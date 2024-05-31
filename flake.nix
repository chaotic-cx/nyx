rec {
  description = "Nix flake for \"too much bleeding-edge\" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).";

  inputs = {
    compare-to.url = "https://flakehub.com/f/chaotic-cx/nix-empty-flake/=0.1.2.tar.gz"; # pinned, used when comparing changes between commits
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/=0.1.1.tar.gz"; # pinned, used by "schemas" output
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default-linux";
    yafas = {
      url = "github:UbiqueLambda/yafas";
      inputs.systems.follows = "systems";
      inputs.flake-schemas.follows = "flake-schemas";
    };

    # thirdy-party repositories
    conduit = {
      url = "github:girlbossceo/conduwuit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.attic.follows = "attic";
      inputs.crane.follows = "crane";
      inputs.fenix.follows = "fenix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-filter.follows = "nix-filter";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jujutsu = {
      url = "github:martinvonz/jj";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.fenix.follows = "fenix";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-filter.follows = "nix-filter";
    };

    # thirdy-party repositories' common dependencies
    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.crane.follows = "crane";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { nixpkgs, yafas, ... }@inputs: yafas.withAllSystems nixpkgs
    (universals: { pkgs, ... }: with universals; {
      # Exposes the packages created by the overlay.
      packages = utils.applyOverlay { inherit pkgs; };

      # I would prefer if we had something stricter, with attribute alphabetical
      # sorting, and optimized for git's diffing. But this is the closer we have.
      formatter = pkgs.nixpkgs-fmt;
    })
    rec {
      # To fix `nix show` and FlakeHub
      schemas = import ./maintenance/schemas { flakes = inputs; };

      # The stars: our overlay and our modules.
      overlays.default = import ./overlays { flakes = inputs; };
      nixosModules = import ./modules/nixos { flakes = inputs; };
      homeManagerModules = import ./modules/home-manager { flakes = inputs; };

      # Dev stuff.
      utils = import ./shared/utils.nix { nyxOverlay = overlays.default; inherit (nixpkgs) lib; };
      devShells = import ./maintenance/dev-shells { flakes = inputs; };
      _dev = import ./maintenance/dev { flakes = inputs; inherit nixConfig utils; };
    };

  # Allows the user to use our cache when using `nix run <thisFlake>`.
  nixConfig = {
    extra-substituters = [ "https://nyx.chaotic.cx/" ];
    extra-trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}
