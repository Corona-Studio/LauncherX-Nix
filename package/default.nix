{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  unzip,
  upx,
  patchelf,
  icu,
  fontconfig,
  freetype,
  libGL,
  libICE,
  libSM,
  libX11,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXinerama,
  libXrandr,
  libXrender,
  libxcb,
  libxkbcommon,
  mesa,
  openssl,
  wayland,
}:

let
  # Pinned build artifacts (zip) keyed by host system.
  builds = {
    x86_64-linux = {
      url = "https://api.corona.studio/Build/get/68817072-c920-4868-96b2-3267c2db89cd";
      hash = "sha256-s5TYUAO4l+2eQXkzIDvheAIL67pt4K83RXPfoHIGYyk=";
      version = "stable-2026-10-01T05-31-38";
    };
    aarch64-linux = {
      url = "https://api.corona.studio/Build/get/de5a3df4-d51e-4156-92cc-07028c4ea4f3";
      hash = "sha256-AcUprG0X+5q7YcU43o7LMlN0nS2jzf/SHe/tnCNj2a8=";
      version = "stable-2026-10-01T05-31-38";
    };
    x86_64-darwin = {
      url = "https://api.corona.studio/Build/get/b8cb35df-de1c-45e1-9eb0-2775a3ad0aab";
      hash = "sha256-GlBknz2kvKRdMF2EwtIZsKuYXoR3+AUsy0REBoPlevU=";
      version = "stable-2026-10-01T05-31-38";
    };
    aarch64-darwin = {
      url = "https://api.corona.studio/Build/get/7e63b58f-6413-4c0a-a279-0e4cffc97db2";
      hash = "sha256-JADV46lgvGOFqqfEX0FO9nOwrUbECEFGWWH2pBd9u9M=";
      version = "stable-2026-10-01T05-31-38";
    };
  };

  build =
    builds.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  version = build.version;

  zip = fetchurl {
    inherit (build) url hash;
    name = "launcherx-${stdenv.hostPlatform.system}.zip";
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
  rpath = lib.makeLibraryPath (
    [
      stdenv.cc.cc.lib
      stdenv.cc.libc
    ]
    ++ runtimeLibs
  );
  interpreter = stdenv.cc.bintools.dynamicLinker;

  meta = {
    description = "LauncherX prebuilt binaries";
    homepage = "https://github.com/Corona-Studio/LauncherX";
    license = lib.licenses.mit;
    mainProgram = "launcherx";
    platforms = builtins.attrNames builds;
  };
in
stdenvNoCC.mkDerivation {
  pname = "launcherx";
  inherit version;

  dontUnpack = true;
  # We patch ELF binaries ourselves (interpreter + rpath) and keep the full rpath
  # because the app dlopens some libs (e.g. ICU, OpenSSL, X11) at runtime, so
  # stdenv's rpath shrinking would incorrectly prune them.
  dontPatchELF = true;
  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    patchelf
    makeWrapper
    upx
  ];

  installPhase =
    if stdenv.hostPlatform.isDarwin then
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
      '';

  inherit meta;
}
