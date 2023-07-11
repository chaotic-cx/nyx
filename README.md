# Chaotic's Nyx ❄️

Flake-compatible Nixpkgs overlay for bleeding-edge and unreleased packages. The first child of chaos.

From the [Chaotic Linux User Group (LUG)](https://github.com/chaotic-cx), the same one that maintains [Chaotic-AUR](https://github.com/chaotic-aur)! 🧑🏻‍💻

## News

A news channel can be found on Telegram: https://t.me/s/chaotic_nyx

## How to use it

We recommend integrating this repo using Flakes:

```nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          chaotic.nixosModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
```

In your `configuration.nix` enable the packages and options that you prefer:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.input-leap-git ];
  chaotic.mesa-git.enable = true;
}
```

### Binary Cache

You'll get the binary cache added to your configuration as soon as you add our default module.
We do this automatically, so we can gracefully update the cache's address and keys without prompting you for manual work.

If you dislike this behavior for any reason, you can disable it with `chaotic.nyx.cache.enable = false`.

**Remember**: If you want to fetch derivations from our cache, you'll need to enable our module and rebuild your system **before** adding these derivations to your configuration.

Commands like `nix run ...`, `nix develop ...`, and others, when using our flake as input, will ask you to add the cache interactively when missing from your user's nix settings.

## List of packages

```nix
[
  ananicy-cpp-rules
  applet-window-appmenu
  applet-window-title
  appmenu-gtk3-module
  beautyline-icons # Garuda Linux's version
  busybox_appletless
  dr460nized-kde-theme
  droid-sans-mono-nerdfont
  fastfetch
  firedragon # and -unwrapped
  gamescope_git
  input-leap_git
  latencyflex-vulkan
  linux_cachyos # the default bore-eevdf scheduler
  linux_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  linuxPackages_cachyos # bore-eevdf, includes their always-working ZFS module
  linuxPackages_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  luxtorpeda # recommended option: chaotic.steam.extraCompatPackages
  mangohud_git
  mesa_git # recommended option: chaotic.mesa-git.enable
  mesa32_git # only x86, recommended option: chaotic.mesa-git.enable
  mpv-vapoursynth
  nordvpn
  openmohaa
  proton-ge-custom # recommended option: chaotic.steam.extraCompatPackages
  river_git
  sway-unwrapped_git
  sway_git # and -unwrapped_git
  swaylock-plugin_git
  waynergy_git
  wlroots_git
  yuzu-early-access_git
]
```

## Running packages

Besides using our module/overlay, you can run packages (without installing) using:

```sh
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#input-leap_git
```

## List of options

```nix
# None of these are in their default value, showing you what kinda of change is possible.
{
  chaotic.appmenu-gtk3-module.enable = true;
  chaotic.gamescope = {
    enable = true;
    package = pkgs.gamescope_git;
    args = [ "--rt" "--prefer-vk-device 8086:9bc4" ];
    env = { "__GLX_VENDOR_LIBRARY_NAME" = "nvidia"; };
    session = {
      enable = true;
      args = [ "--rt" ];
      env = { };
      steamArgs = [ "-tenfoot" "-pipewire-dmabuf" ];
    };
  };
  chaotic.linux_hdr.specialisation.enable = true;
  chaotic.mesa-git.enable = true;
  chaotic.mesa-git.extraPackages = [ pkgs.mesa_git.opencl ];
  chaotic.mesa-git.extraPackages32 = [ pkgs.mesa32_git.opencl ];
  chaotic.nordvpn.enable = false;
  chaotic.nyx.cache.enable = false;
  chaotic.nyx.overlay.enable = false;
  chaotic.nyx.overlay.flakeNixpkgs.config = { allowUnfree = true; };
  chaotic.nyx.overlay.onTopOf = "user-pkgs"; # defaults to "flake-nixpkgs"
  chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];
  chaotic.zfs-impermanence-on-shutdown = {
    enable = true;
    volume = "zroot/ROOT/empty";
    snapshot = "start";
  };
}
```

## Notes

### Our branches

:godmode: Our `nyxpkgs-unstable` branch is the one that's always cached.

:shipit: Sometimes the `main` branch is too, check it through this badge: ![Cache Badge](https://github.com/chaotic-cx/nyx/actions/workflows/build.yml/badge.svg)

### Contributions

We do accept third-party authored PRs.

### Upstream to nixpkgs

If you are interested in pushing any of these packages to the upstream nixpkgs, you have our blessing.

If one of our contributors is mentioned in the deveriation's mantainers list (in this repository) please keep it when pushing to nixpkgs. But, please, tag us on the PR so we can participate in the reviewing.

### Forks and partial code-taking

You are free to use our code, or portions of our code, following the MIT license restrictions.

### Suggestions

If you have any suggestion to enhance our packages, modules, or even the CI's codes, let us know through the GitHub repo's issues.

#### Building over the user's pkgs

For cache reasons, Chaotic-Nyx now defaults to always use nixpkgs as provider of its dependencies.

If you need to change this behavior, set `chaotic.nyx.onTopOf = "user-pkgs".`. Be warned that you mostly won't be able to benefit from our binary cache after this change.

You can also disable our overlay entirely by configuring `chaotic.nyx.overlay.enable`;

## Maintainence

The code in the `devshells` directory is used to automate our CIs and maintainence processes.

### Build them all

To build all the packages and push their cache usptream, use:

```sh
nix develop . -c build-chaotic-nyx
```

This commands will properly skip already-known failures, evaluation failures, building failures, and even skip any chain of failures caused by internal-dependecies. It will also avoid to download what it's already in our cache and in the upstream nixpkgs' cache.

A list of what successfully built, failed to build, hashes of all failures, paths to push to cache and logs will be available at the `/tmp/nix-shell.*/tmp.*/` directory. This directory can be specified with the `NYX_WD` envvar.

### Check for evaluation differerences

You can compare a branch with another like this:

```bash
machine=$(uname -m)-linux
A='github:chaotic-cx/nyx/branch-a'
B='github:chaotic-cx/nyx/branch-b'

nix build --impure --expr \
  "(builtins.getFlake \"$A\").devShells.$machine.comparer.passthru.any \"$B\""
```

After running, you'll find all the derivations that changed in the `result` file.

#### Known failures

All the hashes that are known to produce build-time failures are kept in `devshells/failures.nix`.

Our builder produces a `new-failures.nix` that must be used to update this file in every PR.

#### Banished and rejected packages

There are none (so far).
