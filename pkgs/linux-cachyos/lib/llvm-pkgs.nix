{
  final,
  flakes,
  nyxUtils,
  ...
}:

(final.pkgsLLVM.extend flakes.self.overlays.default).extend (
  finalLLVM: prevLLVM: {
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

    # NOTE: Don't use the one from the cross-compiled pkgsLLVM
    llvmPackages = final.llvmPackages_22;
  }
)
