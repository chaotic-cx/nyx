{
  description = "Flake-compatible nixpkgs-overlay for bleeding-edge and unreleased packages. The first child of Chaos. ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # --- PKGS SOURCES ---
    # Please, set them in alphabetical order

    input-leap-git-src = {
      url = "github:input-leap/input-leap/master";
      flake = false;
    };

    gamescope-git-src = {
      url = "github:ValveSoftware/gamescope/master";
      flake = false;
    };

    mesa-git-src = {
      url = "github:chaotic-cx/mesa-mirror/main";
      flake = false;
    };

    sway-git-src = {
      url = "github:swaywm/sway/master";
      flake = false;
    };

    waynergy-git-src = {
      url = "github:r-c-f/waynergy/master";
      flake = false;
    };

    wlroots-git-src = {
      url = "git+https://gitlab.freedesktop.org/wlroots/wlroots.git?ref=master";
      flake = false;
    };
  };

  outputs = { nixpkgs, self, ... }@inputs: rec {
    # I would prefer if we had something stricter, with attribute alphabetical
    # sorting, and optimized for git's diffing. But this is the closer we have.
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    # The three stars: our overlay, our modules and the packages.

    overlays.default = import ./overlays { inherit inputs; };

    nixosModules = import ./modules { inherit inputs; };

    packages =
      let
        applyOverlay = prev:
          let
            overlayFinal = prev // final // { callPackage = prev.newScope final; };
            final = overlays.default overlayFinal prev;
          in
          final;
      in
      {
        x86_64-linux = applyOverlay nixpkgs.legacyPackages.x86_64-linux;
        aarch64-linux = applyOverlay nixpkgs.legacyPackages.aarch64-linux;
      };

    hydraJobs.default = packages;

    # The following shells are used to help our maintainers and CI/CDs.
    devShells =
      let
        mkShells = final: prev:
          let
            overlayFinal = prev // final // { callPackage = prev.newScope final; };
            builder = overlayFinal.callPackage ./shared/builder.nix
              {
                all-packages = final;
                flakeSelf = self;
                inherit (overlayFinal) nyxUtils;
              };
            evaluated = overlayFinal.callPackage ./shared/eval.nix
              {
                all-packages = final;
                inherit (overlayFinal.nyxUtils) derivationRecursiveFinder;
              };
          in
          {
            default = overlayFinal.mkShell { buildInputs = [ builder ]; };
            evaluator = overlayFinal.mkShell { env.NYX_EVALUATED = evaluated; };
          };
      in
      {
        x86_64-linux = mkShells packages.x86_64-linux
          nixpkgs.legacyPackages.x86_64-linux;
        aarch64-linux = mkShells packages.aarch64-linux
          nixpkgs.legacyPackages.aarch64-linux;
      };
  };

  # Allows the user to use our cache when using `nix run <thisFlake>`.
  nixConfig = {
    extra-substituters = [ "https://nyx.chaotic.cx" ];
    extra-trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };
}
