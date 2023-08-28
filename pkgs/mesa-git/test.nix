{ nixpkgs
, chaotic
, testingDM ? "gdm" # "sddm"
, testingDE ? "gnome" # "plasma5"
, testingSession ? "gnome" # "plasma"
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

    virtualisation.qemu.options = [
      "-m 16G"
      "-vga none"
      "-device virtio-vga-gl"
      "-display gtk,gl=on"
    ];

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

  # TODO: TODO
  testScript = _:
    ''
      start_all()
    '';
})
