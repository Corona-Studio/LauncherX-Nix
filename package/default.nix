{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
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

  rpath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    stdenv.cc.libc
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
  interpreter = stdenv.cc.bintools.dynamicLinker;
in
stdenvNoCC.mkDerivation {
  pname = "launcherx";
  version = build.version;

  dontUnpack = true;
  dontPatchELF = true;
  nativeBuildInputs = [
    unzip
    patchelf
    upx
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    unzip -q "${zip}" -d "$out/bin"
    chmod +x "$out/bin/LauncherX"
    upx -d "$out/bin/LauncherX"

    patchelf \
      --set-interpreter "${interpreter}" \
      --set-rpath "${rpath}" \
      "$out/bin/LauncherX"

    runHook postInstall
  '';

  meta = {
    description = "LauncherX prebuilt binaries";
    homepage = "https://corona.studio/lx";
    license = lib.licenses.unfree;    # mit soon...
    mainProgram = "LauncherX";
    platforms = builtins.attrNames sources;
  };
}
