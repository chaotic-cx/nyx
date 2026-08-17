{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Stuff to test linux-cachyos
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  boot.kernelModules = [
    "i2c-dev"
    "dpdk-kmods"
    "v4l2loopback"
    "xpad-noone"
  ];

  # Stuff to nvidia_cachyos;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = lib.mkOverride 9 [
    "modesetting"
    "nvidia"
  ];
  hardware.nvidia.package = pkgs.nvidia_cachyos;
  hardware.nvidia.open = true;

  # HDR patch
  chaotic.hdr.enable = true;

  assertions = [
    {
      assertion = config.hardware.nvidia.enabled;
      message = "Failing to enable nvidia_cachyos";
    }
  ];

  # Stuff to test zfs_cachyos
  boot.supportedFilesystems.zfs = true;
  boot.zfs.package = pkgs.zfs_cachyos;
  networking.hostId = "318e2410";
}
