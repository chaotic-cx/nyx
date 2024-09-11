fromFlakes:
let
  modulesPerFile = {
    appmenu-gtk3-module = import ./appmenu-gtk3-module.nix;
    duckdns = import ./duckdns.nix;
    hdr = import ./hdr.nix;
    mesa-git = import ./mesa-git.nix;
    nordvpn = import ./nordvpn.nix;
    nyx-cache = import ./nyx-cache.nix fromFlakes;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    scx = import ./scx.nix;
    zfs-impermanence-on-shutdown = import ./zfs-impermanence-on-shutdown.nix;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
