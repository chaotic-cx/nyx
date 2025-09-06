{ final, nyxUtils, ... }:
kernel: _finalModules: prev:

let
  inherit (nyxUtils) markBroken overrideFull;

  fixNoVideo =
    prevDrv:
    prevDrv.overrideAttrs (prevAttrs: {
      passthru = prevAttrs.passthru // {
        settings = overrideFull (final // final.xorg) prevAttrs.passthru.settings;
      };
    });
in
with prev;
{
  nvidia_x11 = fixNoVideo nvidia_x11;
  nvidia_x11_beta = fixNoVideo nvidia_x11_beta;
  nvidia_x11_latest = fixNoVideo nvidia_x11_latest;
  nvidia_x11_legacy535 = fixNoVideo nvidia_x11_legacy535;
  nvidia_dc_535 = markBroken nvidia_dc_535;
  nvidia_dc_565 = markBroken nvidia_dc_565;
  nvidia_x11_legacy470 = markBroken nvidia_x11_legacy470;
  nvidiaPackages = nvidiaPackages.extend (
    _finalNV: prevNV: with prevNV; {
      production = fixNoVideo production;
      stable = fixNoVideo stable;
      beta = fixNoVideo beta;
      vulkan_beta = fixNoVideo vulkan_beta;
      latest = fixNoVideo latest;
      legacy_535 = fixNoVideo legacy_535;
      dc_535 = markBroken dc_535;
      dc_565 = markBroken dc_565;
      legacy_470 = markBroken legacy_470;
    }
  );
  # perf needs systemtap fixed first
  perf = markBroken perf;
  zenpower = zenpower.overrideAttrs (prevAttrs: {
    makeFlags =
      prevAttrs.makeFlags
      ++ kernel.commonMakeFlags
      ++ [
        "KBUILD_CFLAGS="
      ];
  });
}
