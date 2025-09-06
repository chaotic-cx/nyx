# Run with:
# nix build -L .#mesa_git.passthru.tests.smoke-test.driverInteractive && result/bin/nixos-test-driver
{
  nixpkgs,
  chaotic,
  testingDM ? "sddm", # "sddm" | "gdm"
  testingDE ? "plasma6", # "plasma6" | "gnome"
  testingSession ? "plasma", # "gnome" | "plasma"
  testingWithAutoLogin ? true,
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" (
  { pkgs, lib, ... }:
  {
    name = "mesa-git";
    meta.maintainers = with pkgs.lib.maintainers; [ pedrohlc ];

    nodes.machine =
      { pkgs, ... }:
      {
        imports = [
          chaotic.nixosModules.default
          "${nixpkgs}/nixos/tests/common/user-account.nix"
        ];

        # Stuff to test linux-cachyos
        boot.kernelPackages = pkgs.linuxPackages_cachyos;
        boot.kernelModules = [
          "i2c-dev"
          "dpdk-kmods"
          "v4l2loopback"
          "xpad-noone"
        ];
        services.xserver.videoDrivers = [ "nvidia" ];

        # Stuff to test zfs_cachyos
        boot.supportedFilesystems.zfs = true;
        boot.zfs.package = pkgs.zfs_cachyos;
        networking.hostId = "318e2410";

        # Stuff to test mesa-git
        chaotic.mesa-git.enable = true;

        virtualisation.qemu.options = [
          "-m 16G"
          "-vga none"
          "-device virtio-vga-gl"
          "-display gtk,gl=on"
        ];
        virtualisation.qemu.package = lib.mkForce pkgs.qemu_full;

        environment.systemPackages = with pkgs; [
          vulkan-tools
          mesa-demos
          alacritty
        ];

        services = {
          xserver.enable = true;
          displayManager = {
            "${testingDM}".enable = true;
            autoLogin = {
              enable = testingWithAutoLogin;
              user = "alice";
            };
            defaultSession = testingSession;
          };
          desktopManager.${testingDE}.enable = true;
        };
      };

    # TODO: TODO
    testScript = ''
      start_all()
    '';
  }
)
