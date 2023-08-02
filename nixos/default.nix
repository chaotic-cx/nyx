{ flakes, ... }@fromFlakes:
let
  modulesPerFile = {
    appmenu-gtk3-module = import ./appmenu-gtk3-module.nix fromFlakes;
    linux_hdr = import ./linux_hdr.nix fromFlakes;
    mesa_git = import ./mesa-git.nix fromFlakes;
    nordvpn = import ./nordvpn.nix;
    nyx-cache = import ./nyx-cache.nix fromFlakes;
    nyx-overlay = import ./nyx-overlay.nix fromFlakes;
    steam-compat-tools = import ./steam-compat-tools.nix;
    zfs-impermanence-on-shutdown = import ./zfs-impermanence-on-shutdown.nix;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
