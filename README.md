# LauncherX-Nix

This repo packages prebuilt LauncherX binaries from Corona Studio's build API as Nix packages.

## Build

If network is unreliable, use your proxy wrapper for the nix daemon, for example:

```bash
my-proxies-with for-nix-daemon nix build -L .
```

Traditional (non-flake) usage:

```bash
nix-build -A launcherx
```

Flake usage:

```bash
nix build -L .#launcherx
```

Build a specific runtime artifact:

```bash
nix build -L .#linux-x64
nix build -L .#osx-arm64
nix build -L .#win-x64
```

## Run

On NixOS, the package patches the upstream Linux binary with `patchelf` so it runs out-of-the-box.
