fromFlakes:
let
  modulesPerFile = {
    appmenu-gtk3-module = import ./appmenu-gtk3-module.nix;
    duckdns = import ./duckdns.nix;
    linux_hdr = import ./linux_hdr.nix;
    mesa_git = import ./mesa-git.nix;
    nordvpn = import ./nordvpn.nix;
    nyx-cache = import ../common/nyx-cache.nix fromFlakes;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    steam-compat-tools = import ./steam-compat-tools.nix;
    zfs-impermanence-on-shutdown = import ./zfs-impermanence-on-shutdown.nix;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
