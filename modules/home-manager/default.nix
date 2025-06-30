fromFlakes:
let
  modulesPerFile = {
    nyx-cache = import ./nyx-cache.nix fromFlakes;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    nyx-registry = import ../common/nyx-registry.nix fromFlakes;
    bazaar = import ./bazaar.nix;
  };

  default =
    { ... }:
    {
      imports = builtins.attrValues modulesPerFile;
    };
in
modulesPerFile // { inherit default; }
