{ lib, pkgs, ... }:
{
  boot = {
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
}
