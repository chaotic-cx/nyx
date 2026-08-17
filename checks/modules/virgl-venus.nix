{ lib, pkgs, ... }:
let
  testingDisplay = "gtk,gl=on"; # "egl-headless" | "gtk,gl=on"
in
{
  virtualisation.graphics = true;
  virtualisation.qemu.options = [
    "-vga none"
    "-device virtio-vga-gl,hostmem=8G,blob=true,venus=true"
    "-object memory-backend-memfd,id=mem1,size=1G"
    "-machine memory-backend=mem1"
    "-display ${testingDisplay}"
  ];
  virtualisation.qemu.package = lib.mkForce pkgs.qemu_full;

}
