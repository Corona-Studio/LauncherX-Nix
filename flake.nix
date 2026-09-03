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
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          repoPkgs = import ./pkgs/default.nix { inherit pkgs; };
        in
        {
          default = repoPkgs.launcherx;
          launcherx = repoPkgs.launcherx;

          linux-x64 = repoPkgs.launcherx-linux-x64;
          linux-arm64 = repoPkgs.launcherx-linux-arm64;
          osx-x64 = repoPkgs.launcherx-osx-x64;
          osx-arm64 = repoPkgs.launcherx-osx-arm64;
          win-x64 = repoPkgs.launcherx-win-x64;
          win-arm64 = repoPkgs.launcherx-win-arm64;
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
