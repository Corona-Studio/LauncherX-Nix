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

  source = sources.${system} or (throw "Unsupported system: ${system}");

  zip = fetchurl {
    url = source.url;
    hash = source.hash;
    name = "launcherx-${system}.zip";
  };

  libs = [
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
    ++ libs
  );
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
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/launcherx" "$out/bin"
    unzip -q "${zip}" -d "$out/libexec/launcherx"
    chmod +x "$out/libexec/launcherx/LauncherX"
    upx -d "$out/libexec/launcherx/LauncherX"

    patchelf \
      --set-interpreter "${interpreter}" \
      --set-rpath "${rpath}" \
      "$out/libexec/launcherx/LauncherX"

    # The rpath above only helps LauncherX itself. The game is a separate java
    # process spawned by LauncherX, so it finds libs via the inherited
    # LD_LIBRARY_PATH instead.
    makeWrapper "$out/libexec/launcherx/LauncherX" "$out/bin/LauncherX" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libs}" \
      --set LIBGL_DRIVERS_PATH "${mesa}/lib"

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
