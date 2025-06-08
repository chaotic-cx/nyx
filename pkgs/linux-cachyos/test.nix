# Run with:
# nix build -L .#linux_cachyos.passthru.tests.plymouth.driverInteractive && result/bin/nixos-test-driver
{
  nixpkgs,
  chaotic,
  kernelPackages,
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" (
  { pkgs, lib, ... }:
  {
    name = "cachyos-plymouth";
    meta.maintainers = with pkgs.lib.maintainers; [ pedrohlc ];

    nodes.machine =
      { pkgs, ... }:
      {
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
        virtualisation.qemu.package = lib.mkForce pkgs.qemu_full;

        boot = {
          inherit kernelPackages;
          # kernelPackages = pkgs.linuxPackages_latest;

          # Based on https://wiki.nixos.org/wiki/Plymouth

          plymouth = {
            enable = true;
            theme = "rings";
            themePackages = with pkgs; [
              (adi1090x-plymouth-themes.override {
                selected_themes = [ "rings" ];
              })
            ];
          };

          consoleLogLevel = lib.mkForce 3;
          initrd.verbose = false;
          # using mkForce to properly mix with virtualisation stuff
          kernelParams = lib.mkForce [
            "console=ttyS0"
            "clocksource=acpi_pm"
            "lsm=landlock,yama,bpf"

            "boot.shell_on_fail"
            "quiet"
            "rd.systemd.show_status=auto"
            "splash"
            "udev.log_priority=3"

            "plymouth.ignore-serial-consoles"
          ];

          loader.timeout = 0;
        };
      };

    # TODO: TODO
    testScript = ''
      start_all()
    '';
  }
)
