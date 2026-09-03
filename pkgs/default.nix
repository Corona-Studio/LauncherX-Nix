{ pkgs }:

let
  mk = args: pkgs.callPackage ./launcherx-bin.nix { } args;
in
{
  launcherx = mk { };

  # Expose specific pinned artifacts for convenience.
  launcherx-linux-x64 = mk { runtime = "linux-x64"; };
  launcherx-linux-arm64 = mk { runtime = "linux-arm64"; };
  launcherx-osx-x64 = mk { runtime = "osx-x64"; };
  launcherx-osx-arm64 = mk { runtime = "osx-arm64"; };
  launcherx-win-x64 = mk { runtime = "win-x64"; };
  launcherx-win-arm64 = mk { runtime = "win-arm64"; };
}
