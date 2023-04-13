{ inputs, ... }@fromFlakes:
rec {
  default = { ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    };

    imports = [ gamescope linux_hdr mesa_git nyx-cache ];
  };
  gamescope = import ./gamescope.nix fromFlakes;
  linux_hdr = import ./linux_hdr.nix fromFlakes;
  mesa_git = import ./mesa-git.nix fromFlakes;
  nyx-cache = import ./nyx-cache.nix fromFlakes;
}
