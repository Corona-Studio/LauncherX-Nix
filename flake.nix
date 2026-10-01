{
  description = "LauncherX binaries packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          package = nixpkgs.legacyPackages.${system}.callPackage ./package { };
        in
        {
          launcherx = package;
          default = package;

          linux-x64 = package.override { runtime = "linux-x64"; };
          linux-arm64 = package.override { runtime = "linux-arm64"; };
          osx-x64 = package.override { runtime = "osx-x64"; };
          osx-arm64 = package.override { runtime = "osx-arm64"; };
          win-x64 = package.override { runtime = "win-x64"; };
          win-arm64 = package.override { runtime = "win-arm64"; };
        }
      );

      apps = forAllSystems (
        system:
        let
          pkg = self.packages.${system}.default;
        in
        {
          default = {
            type = "app";
            program = "${pkg}/bin/launcherx";
          };
        }
      );
    };
}
