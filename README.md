# Chaotic's Nyx ❄️

Flake-compatible Nixpkgs overlay for bleeding-edge and unreleased packages. The first child of chaos.

From the [Chaotic Linux User Group (LUG)](https://github.com/chaotic-cx), the same one that maintains [Chaotic-AUR](https://github.com/chaotic-aur)! 🧑🏻‍💻

## News

A news channel can be found on Telegram: https://t.me/s/chaotic_nyx

## How to use it

### NixOS

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

### Home Manager

We recommend integrating this repo using Flakes:

```nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, chaotic, ... }: {
    homeConfigurations = {
      hostname = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/default.nix
          chaotic.homeManagerModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
```

In your `home-manager/default.nix` enable the packages:

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.input-leap-git ];
}
```

### Binary Cache

You'll get the binary cache added to your configuration as soon as you add our default module.
We do this automatically, so we can gracefully update the cache's address and keys without prompting you for manual work.

If you dislike this behavior for any reason, you can disable it with `chaotic.nyx.cache.enable = false`.

**Remember**: If you want to fetch derivations from our cache, you'll need to enable our module and rebuild your system **before** adding these derivations to your configuration.

Commands like `nix run ...`, `nix develop ...`, and others, when using our flake as input, will ask you to add the cache interactively when missing from your user's nix settings.

## Lists of options and packages

An always up-to-date list of all our options and packages is available at: [List page](https://chaotic-cx.github.io/nyx/).

## Running packages

Besides using our module/overlay, you can run packages (without installing them) using:

```sh
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#yuzu-early-access_git
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
