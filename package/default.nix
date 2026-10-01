{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  addDriverRunpath,
  makeWrapper,
  unzip,
  upx,
  patchelf,
  alsa-lib,
  fontconfig,
  freetype,
  glfw3-minecraft,
  icu,
  libGL,
  libgbm,
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
  libpulseaudio,
  libxtst,
  libxxf86vm,
  openal,
  openssl,
  vulkan-loader,
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

  # Libraries needed by LauncherX itself (Avalonia/.NET) and by the spawned
  # Minecraft game (java + LWJGL + SDL3 + audio). GPU drivers themselves come
  # from /run/opengl-driver below, not here.
  libs = [
    icu
    fontconfig
    freetype
    libGL
    libgbm
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
    openal
    openssl
    wayland
    vulkan-loader
    glfw3-minecraft
    alsa-lib
    libpulseaudio
    libxtst
    libxxf86vm
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
    # LD_LIBRARY_PATH instead. ${addDriverRunpath.driverLink}/lib is
    # /run/opengl-driver/lib, which holds all GPU vendor drivers (GL + Vulkan)
    # and is resolved generically by nixpkgs' libglvnd / vulkan-loader.
    makeWrapper "$out/libexec/launcherx/LauncherX" "$out/bin/LauncherX" \
      --prefix LD_LIBRARY_PATH : "${addDriverRunpath.driverLink}/lib:${lib.makeLibraryPath libs}"

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
