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

  default = { ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    };

    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
