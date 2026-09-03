{ lib
, stdenv
, stdenvNoCC
, fetchurl
, makeWrapper
, unzip
, patchelf
, icu
, fontconfig
, freetype
, libGL
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
, wayland
}:

{ runtime ? null }:

let
  version = "unstable-2026-08-02";

  # Pinned build artifacts (zip) for each runtime.
  builds = {
    linux-x64 = {
      url = "https://api.corona.studio/Build/get/44143ae2-2848-466f-b84d-aacef4aeec37";
      hash = "sha256-dPwMsEZCLH05r8gN44EyDhJPUHHFO8LzZasLvgz8+xs=";
      kind = "linux";
    };
    linux-arm64 = {
      url = "https://api.corona.studio/Build/get/261d3052-9eb2-435c-896b-344789de0613";
      hash = "sha256-bICC5ZeiIVzffHbB7K8KPqX+kIWDpCZQps0LLiEHwwM=";
      kind = "linux";
    };
    osx-x64 = {
      url = "https://api.corona.studio/Build/get/9566164f-059f-4b1a-82cb-6e244796aa5f";
      hash = "sha256-12g68fthXGVjIu06FwbWiCZ1lQNMQs6UPksIUZ8/CUk=";
      kind = "darwin";
    };
    osx-arm64 = {
      url = "https://api.corona.studio/Build/get/96a653ce-83e8-489d-bc13-5144ed55cc05";
      hash = "sha256-Vs78mopKHOWpMOhzkLoiDZc2dnMdTC+hlgVEHX0sNAw=";
      kind = "darwin";
    };
    # Windows artifacts: packaged for distribution, not runnable on nix.
    win-x64 = {
      url = "https://api.corona.studio/Build/get/1d4f7841-5c31-4218-ab9f-c2002dbe476a";
      hash = "sha256-9DftvszegXNtRqm53msGLnlhSYt+DeVHDXfyod0pBmQ=";
      kind = "windows";
    };
    win-arm64 = {
      url = "https://api.corona.studio/Build/get/4283c5fb-33ea-4a3d-a3fa-6ca5e650135d";
      hash = "sha256-1i5mEbVZ9n5QQ/5JRBugjrHIyYwj8UaUpAcSajAfjR4=";
      kind = "windows";
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

  zip = fetchurl {
    inherit (build) url hash;
    name = "launcherx-${runtime'}.zip";
  };

  runtimeLibs = [
    icu
    fontconfig
    freetype
    libGL
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
  # because .NET loads some libs (e.g. ICU) via dlopen, so stdenv's rpath
  # shrinking would incorrectly prune them.
  dontPatchELF = true;
  nativeBuildInputs = [ unzip ] ++ lib.optionals (build.kind == "linux") [ patchelf makeWrapper ];

  installPhase =
    if build.kind == "linux" then
      ''
        runHook preInstall

        mkdir -p "$out/opt/launcherx" "$out/bin"
        unzip -q "${zip}" -d "$out/opt/launcherx"
        chmod +x "$out/opt/launcherx/LauncherX"

        # Make the upstream binary runnable on NixOS.
        patchelf \
          --set-interpreter "${interpreter}" \
          --set-rpath "${rpath}" \
          "$out/opt/launcherx/LauncherX"

        # The app is a .NET single-file; it extracts native deps at runtime.
        # Provide a stable extract dir and a broad LD_LIBRARY_PATH for dlopen.
        makeWrapper "$out/opt/launcherx/LauncherX" "$out/bin/launcherx" \
          --run 'export DOTNET_BUNDLE_EXTRACT_BASE_DIR="$HOME/.cache/launcherx/${version}-${runtime'}"' \
          --run 'mkdir -p "$DOTNET_BUNDLE_EXTRACT_BASE_DIR"' \
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
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
