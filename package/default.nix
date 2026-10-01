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
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  openssl,
}:

let
  sources = import ./sources.nix;
  system = stdenv.hostPlatform.system;

  source = sources.${system} or (throw "Unsupported system: ${system}");

  zip = fetchurl {
    url = source.url;
    hash = source.hash;
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
    libXext
    libXfixes
    libXi
    libXrandr
    openssl
  ];
  interpreter = stdenv.cc.bintools.dynamicLinker;
in
stdenvNoCC.mkDerivation {
  pname = "launcherx";
  version = source.version;

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
    description = "A next-gen Minecraft launcher with powerful features and a sleek UI.";
    homepage = "https://corona.studio/lx";
    license = lib.licenses.mit;
    mainProgram = "LauncherX";
    platforms = builtins.attrNames sources;
  };
}
