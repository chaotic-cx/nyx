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
      url = "github:Plagman/gamescope/master";
      flake = false;
    };

    mesa-git-src = {
      url = "github:chaotic-aur/mesa-mirror/main";
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

  outputs = { nixpkgs, ... }@inputs:
    let
      defaultOverlay = import ./overlays { inherit inputs; };
    in
    {
      # I would prefer if we had something stricter, with attribute alphabetical
      # sorting, and optimized for git's diffing. But this is the closer we have.
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

      overlays.default = defaultOverlay;

      nixosModules.default = import ./modules { inherit inputs; };

      packages =
        let
          applyOverlay = prev:
            let
              final = defaultOverlay (prev // final) prev;
            in
            final;
        in
        {
          x86_64-linux = applyOverlay nixpkgs.legacyPackages.x86_64-linux;
          aarch64-linux = applyOverlay nixpkgs.legacyPackages.aarch64-linux;
        };
    };
}
