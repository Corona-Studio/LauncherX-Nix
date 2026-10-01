{ lib
, stdenv
, stdenvNoCC
, fetchurl
, makeWrapper
, unzip
, upx
, patchelf
, icu
, fontconfig
, freetype
, libGL
, libICE
, libSM
, libX11
, libXcursor
, libXdamage
, libXext
, libXfixes
, libXi
, libXinerama
, libXrandr
, libXrender
, libxcb
, libxkbcommon
, mesa
, openssl
, wayland
, runtime ? null
}:

let
  # Pinned build artifacts (zip) for each runtime.
  builds = {
    linux-x64 = {
      url = "https://api.corona.studio/Build/get/68817072-c920-4868-96b2-3267c2db89cd";
      hash = "sha256-s5TYUAO4l+2eQXkzIDvheAIL67pt4K83RXPfoHIGYyk=";
      kind = "linux";
      version = "stable-2026-10-01T05-31-38";
    };
    linux-arm64 = {
      url = "https://api.corona.studio/Build/get/de5a3df4-d51e-4156-92cc-07028c4ea4f3";
      hash = "sha256-AcUprG0X+5q7YcU43o7LMlN0nS2jzf/SHe/tnCNj2a8=";
      kind = "linux";
      version = "stable-2026-10-01T05-31-38";
    };
    osx-x64 = {
      url = "https://api.corona.studio/Build/get/b8cb35df-de1c-45e1-9eb0-2775a3ad0aab";
      hash = "sha256-GlBknz2kvKRdMF2EwtIZsKuYXoR3+AUsy0REBoPlevU=";
      kind = "darwin";
      version = "stable-2026-10-01T05-31-38";
    };
    osx-arm64 = {
      url = "https://api.corona.studio/Build/get/7e63b58f-6413-4c0a-a279-0e4cffc97db2";
      hash = "sha256-JADV46lgvGOFqqfEX0FO9nOwrUbECEFGWWH2pBd9u9M=";
      kind = "darwin";
      version = "stable-2026-10-01T05-31-38";
    };
    # Windows artifacts: packaged for distribution, not runnable on nix.
    win-x64 = {
      url = "https://api.corona.studio/Build/get/8f9d0ff7-6b4a-46cf-960d-fae6d976f0b0";
      hash = "sha256-JH4Akq5iwqGm5aupdBiHXjxpY1j1EMiCax4QD6+dHnk=";
      kind = "windows";
      version = "stable-2026-10-01T05-31-38";
    };
    win-arm64 = {
      url = "https://api.corona.studio/Build/get/0e82bd85-b78f-41f8-8c30-c4762672bf6e";
      hash = "sha256-TkrQXynJ//bofDX4YRkkPvLIVHN/uSNmimTmb0r3ekU=";
      kind = "windows";
      version = "stable-2026-10-01T05-31-38";
    };
  };

  defaultRuntime =
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64 then "linux-arm64" else
    if stdenv.hostPlatform.isLinux then "linux-x64" else
    if stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64 then "osx-arm64" else
    if stdenv.hostPlatform.isDarwin then "osx-x64" else
    throw "Unsupported host platform";

  runtime' = if runtime == null then defaultRuntime else runtime;
  build = builds.${runtime'} or (throw "Unknown runtime: ${runtime'}");
  version = build.version;

  zip = fetchurl {
    inherit (build) url hash;
    name = "launcherx-${runtime'}.zip";
  };

  runtimeLibs = [
    icu
    fontconfig
    freetype
    libGL
    libICE
    libSM
    libX11
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXinerama
    libXrandr
    libXrender
    libxcb
    libxkbcommon
    mesa
    openssl
    wayland
  ];

  # Generic upstream linux binaries need a proper dynamic linker + rpath on NixOS.
  rpath = lib.makeLibraryPath ([ stdenv.cc.cc.lib stdenv.cc.libc ] ++ runtimeLibs);
  interpreter = stdenv.cc.bintools.dynamicLinker;
in
stdenvNoCC.mkDerivation {
  pname = "launcherx";
  inherit version;

  dontUnpack = true;
  # We patch ELF binaries ourselves (interpreter + rpath) and keep the full rpath
  # because the app dlopens some libs (e.g. ICU, OpenSSL, X11) at runtime, so
  # stdenv's rpath shrinking would incorrectly prune them.
  dontPatchELF = true;
  nativeBuildInputs = [ unzip ] ++ lib.optionals (build.kind == "linux") [ patchelf makeWrapper upx ];

  installPhase =
    if build.kind == "linux" then
      ''
        runHook preInstall

        mkdir -p "$out/opt/launcherx" "$out/bin"
        unzip -q "${zip}" -d "$out/opt/launcherx"
        chmod +x "$out/opt/launcherx/LauncherX"

        # Upstream ships UPX-compressed binaries, which have no section headers
        # and cannot be patched. Decompress first so patchelf works.
        upx -d "$out/opt/launcherx/LauncherX"

        # Make the upstream binary runnable on NixOS.
        patchelf \
          --set-interpreter "${interpreter}" \
          --set-rpath "${rpath}" \
          "$out/opt/launcherx/LauncherX"

        # NativeAOT apps dlopen some libs (ICU, OpenSSL, X11) at runtime; keep a
        # broad LD_LIBRARY_PATH as a safety net in addition to the rpath.
        makeWrapper "$out/opt/launcherx/LauncherX" "$out/bin/launcherx" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"

        runHook postInstall
      ''
    else if build.kind == "darwin" then
      ''
        runHook preInstall
        mkdir -p "$out/Applications" "$out/bin"
        unzip -q "${zip}" -d "$out/Applications"
        chmod +x "$out/Applications/LauncherX.app/Contents/MacOS/LauncherX"
        ln -s "$out/Applications/LauncherX.app/Contents/MacOS/LauncherX" "$out/bin/launcherx"
        runHook postInstall
      ''
    else
      ''
        runHook preInstall
        mkdir -p "$out/share/launcherx-windows/${runtime'}"
        unzip -q "${zip}" -d "$out/share/launcherx-windows/${runtime'}"
        runHook postInstall
      '';

  meta = {
    description = "LauncherX prebuilt binaries";
    homepage = "https://github.com/Corona-Studio/LauncherX";
    license = lib.licenses.mit;
    mainProgram = "launcherx";
    platforms = lib.platforms.all;
  };
}
