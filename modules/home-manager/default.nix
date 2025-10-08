fromFlakes:
let
  modulesPerFile = {
    nyx-cache = import ./nyx-cache.nix fromFlakes;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    nyx-registry = import ../common/nyx-registry.nix fromFlakes;
  };

  default =
    { ... }:
    {
      imports = builtins.attrValues modulesPerFile;
    };
in
modulesPerFile // { inherit default; }
