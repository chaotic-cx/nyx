{ inputs, ... }@fromFlakes:
rec {
  default = { ... }: {
    config = {
      nixpkgs.overlays = [ inputs.self.overlays.default ];
    };

    imports = [ appmenu-gtk3-module gamescope linux_hdr mesa_git ];
  };
  appmenu-gtk3-module = import ./appmenu-gtk3-module.nix fromFlakes;
  gamescope = import ./gamescope.nix fromFlakes;
  linux_hdr = import ./linux_hdr.nix fromFlakes;
  mesa_git = import ./mesa-git.nix fromFlakes;
}
