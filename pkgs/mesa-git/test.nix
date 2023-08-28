{ nixpkgs
, chaotic
, testingDM ? "sddm"
, testingDE ? "plasma5"
, testingSession ? "plasma"
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ pkgs, ... }: {
  name = "mesa-git";
  meta.maintainers = with pkgs.lib.maintainers; [ pedrohlc ];

  nodes.machine = { pkgs, ... }: {
    imports = [
      chaotic.nixosModules.default
      "${nixpkgs}/nixos/tests/common/user-account.nix"
    ];
    chaotic.mesa-git.enable = true;

    virtualisation = {
      resolution = { x = 800; y = 1280; };
      qemu.options = [
        "-m 16G"
        "-vga none"
        "-device virtio-vga-gl,xres=800,yres=1280"
        "-display gtk,gl=on"
      ];
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      mesa-demos
      alacritty
    ];

    services.xserver = {
      enable = true;
      displayManager = {
        "${testingDM}".enable = true;
        autoLogin = {
          enable = true;
          user = "alice";
        };
        defaultSession = testingSession;
      };
      desktopManager.${testingDE}.enable = true;
    };
  };

  testScript = { nodes, ... }:
    let
      user = nodes.machine.users.users.alice;
    in
    ''
      start_all()
    '';
})
