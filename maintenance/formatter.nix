pkgs:
pkgs.nixfmt-tree.override {
  settings = {
    tree-root-file = ".git/index";
    excludes = [
      "maintenance/failures.aarch64-darwin.nix"
      "maintenance/failures.aarch64-linux.nix"
      "maintenance/failures.x86_64-linux.nix"
    ];
    formatter.nixfmt = {
      command = "nixfmt";
      includes = [ "*.nix" ];
    };
  };
}
