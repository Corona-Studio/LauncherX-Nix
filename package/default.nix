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
    patchelf
    makeWrapper
    upx
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/launcherx" "$out/bin"
    unzip -q "${zip}" -d "$out/opt/launcherx"
    chmod +x "$out/opt/launcherx/LauncherX"
    upx -d "$out/opt/launcherx/LauncherX"

    patchelf \
      --set-interpreter "${interpreter}" \
      --set-rpath "${rpath}" \
      "$out/opt/launcherx/LauncherX"

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
