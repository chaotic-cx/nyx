# Run interactively with:
# nix run .#checks.x86_64-linux.all-in-one.driverInteractive
{
  nixpkgs,
  chaotic,
  system,
}:

let
  pkgs = import nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
    };
    overlays = [ chaotic.overlays.default ]; # IMPORTANT
  };

  test = {
    name = "chaotic-nyx-one";
    meta.maintainers = with pkgs.lib.maintainers; [ pedrohlc ];

    nodes.machine = _inputs: {
      imports = [
        chaotic.nixosModules.default
        "${nixpkgs}/nixos/tests/common/user-account.nix"
        ./modules/autologin.nix
        ./modules/cachyos.nix
        ./modules/mesa-git.nix
        ./modules/plymouth.nix
      ];

      chaotic.nyx.overlay.enable = false;

      virtualisation.memorySize = 2 * 1024;
    };

    interactive.nodes.machine = _inputs: {
      imports = [
        ./modules/virgl-venus.nix
      ];
    };

    # TODO: TODO
    testScript = ''
      start_all()

      machine.wait_for_unit("graphical.target")

      out = machine.succeed("(glxinfo | grep 'renderer') || echo NOT INTERACTIVE")
      print(out)
    '';
  };
in
pkgs.testers.runNixOSTest test
