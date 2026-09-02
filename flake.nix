{
  description = "LauncherX binaries packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      pkgFor = pkgs: runtime:
        let
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
          };

          # Filled from known-good IDs we already inspected.
          resolvedBuilds = builds // {
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

          build = resolvedBuilds.${runtime} or (throw "Unknown runtime: ${runtime}");

          zip = pkgs.fetchurl {
            inherit (build) url hash;
            name = "launcherx-${runtime}.zip";
          };
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "launcherx";
          version = "unstable-2026-08-02";

          dontUnpack = true;
          nativeBuildInputs = [ pkgs.makeWrapper pkgs.unzip ];

          installPhase =
            if build.kind == "linux" then
              ''
                runHook preInstall
                mkdir -p "$out/opt/launcherx" "$out/bin"
                unzip -q "${zip}" -d "$out/opt/launcherx"
                chmod +x "$out/opt/launcherx/LauncherX"
                ln -s "$out/opt/launcherx/LauncherX" "$out/bin/launcherx"
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
              # Windows artifacts: package them for distribution, but no runnable app on nix.
              ''
                runHook preInstall
                mkdir -p "$out/share/launcherx-windows/${runtime}"
                unzip -q "${zip}" -d "$out/share/launcherx-windows/${runtime}"
                runHook postInstall
              '';

          meta = {
            description = "LauncherX prebuilt binaries";
            license = pkgs.lib.licenses.mit;
            platforms = pkgs.lib.platforms.all;
          };
        };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          runtime =
            if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then "linux-arm64" else
            if pkgs.stdenv.hostPlatform.isLinux then "linux-x64" else
            if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then "osx-arm64" else
            if pkgs.stdenv.hostPlatform.isDarwin then "osx-x64" else
            throw "Unsupported host platform";
        in
        {
          default = pkgFor pkgs runtime;
          linux-x64 = pkgFor pkgs "linux-x64";
          linux-arm64 = pkgFor pkgs "linux-arm64";
          osx-x64 = pkgFor pkgs "osx-x64";
          osx-arm64 = pkgFor pkgs "osx-arm64";
          win-x64 = pkgFor pkgs "win-x64";
          win-arm64 = pkgFor pkgs "win-arm64";
        });

      apps = forAllSystems (system:
        let
          pkg = self.packages.${system}.default;
        in
        {
          default = {
            type = "app";
            program = "${pkg}/bin/launcherx";
          };
        });
    };
}
