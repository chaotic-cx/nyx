flakes: pkgs:

(pkgs.pkgsLLVM.extend flakes.self.overlays.default).extend (
  final: prev: {
    inherit (pkgs)
      dbus
      libdrm
      libgbm
      libGL
      libxv
      libtirpc
      wayland
      xorg
      ;
  }
)
