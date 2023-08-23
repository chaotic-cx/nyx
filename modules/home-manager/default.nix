fromFlakes:
let
  modulesPerFile = {
    nyx-cache = import ../common/nyx-cache.nix;
    nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
