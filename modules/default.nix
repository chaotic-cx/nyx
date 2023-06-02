{ inputs, ... }@fromFlakes:
let
  modulesPerFile = {
    appmenu-gtk3-module = import ./appmenu-gtk3-module.nix fromFlakes;
    gamescope = import ./gamescope.nix fromFlakes;
    linux_hdr = import ./linux_hdr.nix fromFlakes;
    mesa_git = import ./mesa-git.nix fromFlakes;
    steam-compat-tools = import ./steam-compat-tools.nix;
    zfs-impermanence-on-shutdown = import ./zfs-impermanence-on-shutdown.nix;
  };

  default = { pkgs, ... }: {
    config = {
      nixpkgs.overlays = [
        (_: userPrev:
          let
          input = inputs.nixpkgs.legacyPackages.${pkgs.system};
          ourPackages = inputs.self.overlays.default (input // ourPackages) input;
          in userPrev // ourPackages
        )
      ];
    };

    imports = builtins.attrValues modulesPerFile;
  };

  defaultWithFollow = { ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    };

    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
