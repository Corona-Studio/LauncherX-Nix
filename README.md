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

The default package (`launcherx`) auto-selects the runtime matching your platform:

```nix
launcherx.packages.${system}.launcherx
```

Or try it directly from the CLI:

```console
$ nix shell github:yueyinqiu/LauncherX-Nix
```

Each runtime is also pinned individually:

```nix
launcherx.packages.${system}.linux-x64
launcherx.packages.${system}.linux-arm64
launcherx.packages.${system}.osx-x64
launcherx.packages.${system}.osx-arm64
launcherx.packages.${system}.win-x64
launcherx.packages.${system}.win-arm64
```

| Attribute               | Runtime       | Notes                           |
| ----------------------- | ------------- | ------------------------------- |
| `launcherx` / `default` | auto          | Picked from the host platform   |
| `linux-x64`             | `linux-x64`   | patchelf + UPX-decompressed     |
| `linux-arm64`           | `linux-arm64` | patchelf + UPX-decompressed     |
| `osx-x64`               | `osx-x64`     | `.app` bundle                   |
| `osx-arm64`             | `osx-arm64`   | `.app` bundle                   |
| `win-x64`               | `win-x64`     | unpacked only, for distribution |
| `win-arm64`             | `win-arm64`   | unpacked only, for distribution |

The Linux binaries are UPX-compressed upstream; this flake decompresses them and
patches the interpreter and rpath so they run out-of-the-box on NixOS.

## Updating

Build artifacts are pinned in `package/default.nix`. To bump them, regenerate the
list with:

```console
$ dotnet run generator.cs
```

and update the URLs/hashes (and per-runtime `version`) accordingly.
