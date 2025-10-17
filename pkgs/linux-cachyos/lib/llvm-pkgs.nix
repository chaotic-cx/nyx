{
  final,
  flakes,
  nyxUtils,
  ...
}:

(final.pkgsLLVM.extend flakes.self.overlays.default).extend (
  _finalLLVM: prevLLVM: {
    inherit (final)
      dbus
      libdrm
      libgbm
      libGL
      libxv
      libtirpc
      wayland
      xorg
      ;
    cups = nyxUtils.markBroken prevLLVM.cups;
  }
)
