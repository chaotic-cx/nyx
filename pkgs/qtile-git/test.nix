{ nixpkgs
, chaotic
, testingBackend ? "wayland"
, testingWithAutoLogin ? true
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  name = "qtile_git";
  meta.maintainers = with pkgs.lib.maintainers; [ pedrohlc ];

  nodes.machine = { pkgs, ... }: {
    imports = [
      chaotic.nixosModules.default
      "${nixpkgs}/nixos/tests/common/user-account.nix"
    ];

    virtualisation.qemu.options = [
      "-m 16G"
      "-vga none"
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];

    environment.systemPackages = with pkgs; [
      alacritty
    ];

    services.xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
        autoLogin = {
          enable = testingWithAutoLogin;
          user = "alice";
        };
        defaultSession = "${if testingBackend == "wayland" then "wayland" else "none"}+qtile";
      };
      windowManager.qtile = {
        backend = testingBackend;
        package = pkgs.qtile-module_git;
        extraPackages = _pythonPackages: [ pkgs.qtile-extras_git ];
        configFile = pkgs.writeTextFile {
          name = "qtile-config.py";
          text = ''
            from libqtile.log_utils import logger
            import qtile_extras
            logger.warning("This is after importing qtile_extras")
          '';
        };
      };
    };
    chaotic.qtile.enable = true;
  };

  # TODO: TODO
  testScript =
    ''
      start_all()
    '';
})
