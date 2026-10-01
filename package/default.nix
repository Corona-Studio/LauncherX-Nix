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
  sources = import ./sources.nix;
  system = stdenv.hostPlatform.system;

  build = sources.${system} or (throw "Unsupported system: ${system}");

  zip = fetchurl {
    url = build.url;
    hash = build.hash;
    name = "launcherx-${system}.zip";
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
in
stdenvNoCC.mkDerivation {
  pname = "launcherx";
  version = build.version;

  dontUnpack = true;
  dontPatchELF = true;
  nativeBuildInputs = [
    unzip
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    patchelf
    makeWrapper
    upx
  ];

  installPhase = ''
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

  meta = {
    description = "LauncherX prebuilt binaries";
    homepage = "https://github.com/Corona-Studio/LauncherX";
    license = lib.licenses.mit;
    mainProgram = "launcherx";
    platforms = builtins.attrNames sources;
  };
}
