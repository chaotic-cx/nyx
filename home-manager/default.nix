{ flakes, ... }@fromFlakes:
let
  modulesPerFile = {
    nyx-cache = import ../nixos/nyx-cache.nix fromFlakes;
    nyx-overlay = import ../nixos/nyx-overlay.nix fromFlakes;
  };

  default = { ... }: {
    imports = builtins.attrValues modulesPerFile;
  };
in
modulesPerFile // { inherit default; }
