# Nyx

Flake-compatible nixpkgs-overlay for bleeding-edge and unreleased packages. The first child of Chaos.

## How to use it

We recommend to integrate this repo using Flakes:

```nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-aur/nyx";
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          chaotic.nixosModules.default
          ({ pkgs, ... }: {
            environment.systemPackages = [ pkgs.input-leap-git ];
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
  gamescope-git
  input-leap-git
  libei
  linux_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  linuxPackages_hdr # recommended option: chaotic.linux_hdr.specialisation.enable
  mesa-git # recommended option: chaotic.mesa-git.enable
  mesa-git-32 # only x86, recommended option: chaotic.mesa-git.enable
  sway-unwrapped-git
  sway-git
  waynergy-git
  wlroots-git
]
```

## List of options

```nix
{
  chaotic.mesa-git.enable = true;
  chaotic.linux_hdr.specialisation.enable = true;
}
```

## Cache

Soon...
