rec {
  description = "Flake-compatible nixpkgs-overlay for bleeding-edge and unreleased packages. The first child of Chaos. ";

  inputs = {
    # --- UTILITIES ---

    compare-to.url = "github:chaotic-cx/nix-empty-flake";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs: rec {
    # I would prefer if we had something stricter, with attribute alphabetical
    # sorting, and optimized for git's diffing. But this is the closer we have.
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    # The three stars: our overlay, our modules and the packages.

    overlays.default = import ./overlays { flakes = inputs; };

    nixosModules = import ./modules/nixos { flakes = inputs; };
    homeManagerModules = import ./modules/home-manager { flakes = inputs; };

    packages =
      let
        applyOverlay = prev:
          let
            overlayFinal = prev // ourPackages // { callPackage = prev.newScope overlayFinal; };
            ourPackages = overlays.default overlayFinal prev;
          in
          ourPackages;
      in
      {
        x86_64-linux = applyOverlay nixpkgs.legacyPackages.x86_64-linux;
        aarch64-linux = applyOverlay nixpkgs.legacyPackages.aarch64-linux;
      };

    hydraJobs.default = packages;
    devShells = import ./devshells { inherit packages homeManagerModules; flakes = inputs; };

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
