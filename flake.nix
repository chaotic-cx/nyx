{
  description = "Nix flake for \"too much bleeding-edge\" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).";

  inputs = {
    # For all users
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Used by "homeManagerModules" (for HM users)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Used by "schemas" output (for FlakeHub and "nix show", pinned)
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/=0.5.0.tar.gz";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      vendored = import ./vendor;
      flakes = vendored // inputs;

      eachSystem =
        accu: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        accu
        // {
          # Exposes the packages created by the overlay.
          legacyPackages = (accu.legacyPackages or { }) // {
            ${system} = accu.utils.applyOverlay { inherit pkgs; };
          };

          # Needed to build without impure
          unrestrictedPackages = (accu.unrestrictedPackages or { }) // {
            ${system} = accu.utils.applyOverlay {
              pkgs = import nixpkgs {
                inherit system;
                config = {
                  allowUnfree = true;
                  allowUnsupportedSystem = true;
                  nvidia.acceptLicense = true;
                };
              };
            };
          };

          # For CI
          checks =
            (accu.checks or { })
            // (
              if system == "x86_64-linux" then
                {
                  ${system} = import ./checks flakes pkgs;
                }
              else
                { }
            );

          # I would prefer if we had something stricter, with attribute alphabetical
          # sorting, and optimized for git's diffing. But this is the closer we have.
          formatter = (accu.formatter or { }) // {
            ${system} = import ./maintenance/formatter.nix pkgs;
          };
        };

      universals = {
        # To fix `nix show` and FlakeHub
        schemas = import ./maintenance/schemas { inherit flakes; };

        # The stars: our overlay and our modules.
        overlays.default = import ./overlays { inherit flakes; };
        overlays.cache-friendly = import ./overlays/cache-friendly.nix { inherit flakes; };
        nixosModules = import ./modules/nixos { inherit flakes; };
        homeModules = import ./modules/home-manager { inherit flakes; };
        homeManagerModules = self.homeModules;

        # In case you need something from our vendored flakes
        inherit vendored;

        # Beloved flakes making me have a flat list of packages
        packages = import ./maintenance/flat-packages-cache.nix self.legacyPackages;

        # Dev stuff.
        utils = import ./shared/utils.nix {
          nyxOverlay = self.overlays.default;
          inherit (nixpkgs) lib;
        };
        inherit (import ./flake.nix) nixConfig;
      };
    in
    builtins.foldl' eachSystem universals [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];

  # Allows the user to use our cache when using `nix run <thisFlake>`.
  nixConfig = {
    extra-substituters = [
      "https://nyx-cache.chaotic.cx/"
    ];
    extra-trusted-public-keys = [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];
  };
}
