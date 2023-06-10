{
  description = "Flake-compatible nixpkgs-overlay for bleeding-edge and unreleased packages. The first child of Chaos. ";

  inputs = {
    # --- UTILITIES ---

    compare-to.url = "github:chaotic-cx/nix-empty-flake";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # --- PKGS SOURCES ---
    # Please, sort them in alphabetical order

    input-leap-git-src = {
      url = "github:input-leap/input-leap/master";
      flake = false;
    };

    gamescope-git-src = {
      url = "github:ValveSoftware/gamescope/master";
      flake = false;
    };

    mangohud-git-src = {
      url = "github:flightlessmango/MangoHud/master";
      flake = false;
    };

    mesa-git-src = {
      url = "github:chaotic-cx/mesa-mirror/main";
      flake = false;
    };

    river-git-src = {
      url = "git+https://github.com/riverwm/river?submodules=1";
      flake = false;
    };

    sway-git-src = {
      url = "github:swaywm/sway/master";
      flake = false;
    };

    swaylock-plugin-git-src = {
      url = "github:mstoeckl/swaylock-plugin/main";
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

    yuzu-ea-git-src = {
      url = "github:pineappleEA/pineapple-src/main";
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
    devShells = import ./devshells { inherit inputs packages; };
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
