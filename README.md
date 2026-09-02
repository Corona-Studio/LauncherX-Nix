# LauncherX-Nix

This repo packages prebuilt LauncherX binaries from Corona Studio's build API as Nix packages.

## Build

If network is unreliable, use your proxy wrapper for the nix daemon, for example:

```bash
my-proxies-with for-nix-daemon nix build -L .
```

Build a specific runtime artifact:

```bash
nix build -L .#linux-x64
nix build -L .#osx-arm64
nix build -L .#win-x64
```

## Run

On NixOS, upstream generic Linux binaries may not run out-of-the-box due to dynamic linker constraints.
If you want a quick way, you can try running via an FHS environment (requires unfree packages):

```bash
NIXPKGS_ALLOW_UNFREE=1 my-proxies-with for-nix-daemon nix run --impure nixpkgs#steam-run -- .# --help
```
