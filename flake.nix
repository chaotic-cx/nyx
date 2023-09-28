rec {
  description = "Nix flake for \"too much bleeding-edge\" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).";

  inputs = {
    # --- UTILITIES ---
    compare-to.url = "https://flakehub.com/f/chaotic-cx/nix-empty-flake/0.1.2.tar.gz"; # pinned
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.1.tar.gz"; # pinned
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default-linux";
    yafas = {
      url = "https://flakehub.com/f/UbiqueLambda/yafas/0.1.0.tar.gz";
      inputs.systems.follows = "systems";
      inputs.flake-schemas.follows = "flake-schemas";
    };
  };

  outputs = { nixpkgs, yafas, ... }@inputs: yafas.withAllSystems nixpkgs
    (universals: { pkgs, ... }: with universals; {
      # Just exposes the packages created by the overlay.
      packages =
        let
          overlayFinal = pkgs // ourPackages // { callPackage = pkgs.newScope overlayFinal; };
          ourPackages = overlays.default overlayFinal pkgs;
        in
        ourPackages;

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
      devShells = import ./maintenance/dev-shells { flakes = inputs; };
      _dev = {
        x86_64-linux =
          nixpkgs.lib.nixosSystem {
            modules = [ nixosModules.default ];
            system = "x86_64-linux";
          };
        inherit nixConfig;
      };
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
