# LauncherX-Nix

Nix packaging for [LauncherX](https://github.com/Corona-Studio/LauncherX) prebuilt binaries, downloaded from Corona Studio's build API and patched to run on Nix/NixOS.

## Adding as a flake input

```nix
{
  inputs = {
    launcherx.url = "github:yueyinqiu/LauncherX-Nix";
  };
}
```

## Package

The package (`launcherx`, also exposed as `default`) auto-selects the runtime
matching your platform:

```nix
launcherx.packages.${system}.launcherx
```

Or try it directly from the CLI:

```console
$ nix shell github:yueyinqiu/LauncherX-Nix
```

Supported platforms are `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and
`aarch64-darwin`. The Linux binaries are UPX-compressed upstream; this flake
decompresses them and patches the interpreter and rpath so they run
out-of-the-box on NixOS.

## Updating

Build artifacts are pinned in `package/default.nix`. To bump them, regenerate the
list with:

```console
$ dotnet run generator.cs
```

and update the URLs/hashes (and per-runtime `version`) accordingly.
