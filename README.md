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

## List of packages

```nix
[
  ananicy-cpp-rules
  applet-window-appmenu
  applet-window-title
  appmenu-gtk3-module
  beautyline-icons # Garuda Linux's version
  directx-headers_next
  directx-headers32_next # only x86
  dr460nized-kde-theme
  droid-sans-mono-nerdfont
  fastfetch
  firedragon # and -unwrapped
  gamescope_git
  input-leap_git
  latencyflex-vulkan
  libei
  libei_0_4
  libei_0_5
  libei_1
  linux_cachyos # the default BORE scheduler
  linux_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  linuxPackages_cachyos # the default BORE scheduler
  linuxPackages_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  luxtorpeda # recommended option: chaotic.steam.extraCompatPackages
  mangohud_git
  mesa_git # recommended option: chaotic.mesa-git.enable
  mesa32_git # only x86, recommended option: chaotic.mesa-git.enable
  mpv-vapoursynth
  openmohaa
  proton-ge-custom # recommended option: chaotic.steam.extraCompatPackages
  sway-unwrapped_git
  sway_git # and -unwrapped_git
  swaylock-plugin_git
  vulkan-headers_next
  vulkan-loader_next
  wayland_next
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
{
  chaotic.appmenu-gtk3-module.enable = true;
  chaotic.mesa-git.enable = true;
  chaotic.mesa-git.extraPackages = [ pkgs.mesa_git.opencl ];
  chaotic.mesa-git.extraPackages32 = [ pkgs.mesa32_git.opencl ];
  chaotic.linux_hdr.specialisation.enable = true;
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
  chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];
  chaotic.zfs-impermanence-on-shutdown = {
    enable = true;
    volume = "zroot/ROOT/empty";
    snapshot = "start";
  };
}
```

## Cache

To use our pre-build packages and speed the installation process, add these options to your configuration:

```nix
{
  nix.settings = {
    extra-substituters = [
      "https://nyx.chaotic.cx"
    ];
    extra-trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}
```

## Notes

### Our branches

:godmode: Our `nyxpkgs-unstable` branch is the one that's always cached.

:shipit: Sometimes the `main` branch is too, check it through this badge: [![CircleCI](https://dl.circleci.com/status-badge/img/gh/chaotic-cx/nyx/tree/main.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/chaotic-cx/nyx/tree/main)

### Contributions

We do accept third-party authored PRs.

### Upstream to nixpkgs

If you are interested in pushing any of these packages to the upstream nixpkgs, you have our blessing.

If one of our contributors is mentioned in the deveriation's mantainers list (in this repository) please keep it when pushing to nixpkgs. But, please, tag us on the PR so we can participate in the reviewing.

### Forks and partial code-taking

You are free to use our code, or portions of our code, following the MIT license restrictions.

### Suggestions

If you have any suggestion to enhance our packages, modules, or even the CI's codes, let us know through the GitHub repo's issues.

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
  "(builtins.getFlake \"$A\").devShells.$machine.comparer.passthru.any \"$B\"
```

After running, you'll find all the derivations that changed in the `result` file.

#### Known failures.

All the hashes that are known to produce build-time failures are kept in `devshells/failures.nix`.

Our builder produces a `new-failures.nix` that must be used to update this file in every PR.
