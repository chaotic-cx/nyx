fromFlakes:
let
  modulesPerFile = {
    appmenu-gtk3-module = import ./appmenu-gtk3-module.nix;
    duckdns = import ./duckdns.nix;
    hdr = import ./hdr.nix;
    mesa-git = import ./mesa-git.nix;
    nordvpn = import ./nordvpn.nix;
    nyx-home-check = import ./nyx-home-check.nix;
    nyx-cache = import ./nyx-cache.nix fromFlakes;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    nyx-registry = import ../common/nyx-registry.nix fromFlakes;
    zfs-impermanence-on-shutdown = import ./zfs-impermanence-on-shutdown.nix;
    owl-wlr = import ./owl-wlr.nix;
  };

  default =
    { ... }:
    {
      imports = builtins.attrValues modulesPerFile;
    };
in
modulesPerFile // { inherit default; }
