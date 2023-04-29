# Chaotic's Nyx ❄️

Flake-compatible Nixpkgs overlay for bleeding-edge and unreleased packages. The first child of chaos.

From the [Chaotic Linux User Group (LUG)](https://github.com/chaotic-cx), the same one that maintains [Chaotic-AUR](https://github.com/chaotic-aur)! 🧑🏻‍💻

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
          chaotic.nixosModules.default
          ({ pkgs, ... }: {
            environment.systemPackages = [ pkgs.input-leap_git ];
            chaotic.mesa-git.enable = true;
          })
        ];
      };
    };
  };
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
  firedragon # and -unwrapped
  gamescope_git
  input-leap_git
  libei
  libei_0_4
  linux_cachyos # the default BORE scheduler
  linux_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  linuxPackages_cachyos # the default BORE scheduler
  linuxPackages_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  luxtorpeda # recommended option: chaotic.steam.extraCompatPackages
  mesa_git # recommended option: chaotic.mesa-git.enable
  mesa32_git # only x86, recommended option: chaotic.mesa-git.enable
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

Besides using our module/overlay, you can run packages using:

```sh
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#input-leap_git
```

## List of options

```nix
{
  chaotic.appmenu-gtk3-module.enable = true;
  chaotic.mesa-git.enable = true; # requires `--impure`
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
    };
  };
  chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];
}
```

## Cache

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
