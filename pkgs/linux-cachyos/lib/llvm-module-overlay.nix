{ final, nyxUtils, ... }:
kernel: _finalModules: prevModules:

let
  inherit (nyxUtils) markBroken overrideFull multiOverride;

  fixNoVideo =
    prevDrv:
    prevDrv.overrideAttrs (prevAttrs: {
      passthru = prevAttrs.passthru // {
        settings = overrideFull (final // final.xorg) prevAttrs.passthru.settings;
      };
    });
in
with prevModules;
{
  evdi =
    multiOverride prevModules.evdi
      {
        inherit (final) python3;
      }
      (prevAttrs: rec {
        env = prevAttrs.env // {
          CFLAGS = "";
        };
        makeFlags = prevAttrs.makeFlags ++ [
          "CFLAGS=${
            builtins.replaceStrings [ "discarded-qualifiers" ] [ "ignored-qualifiers" ] prevAttrs.env.CFLAGS
          }"
        ];
        postPatch = ''
          substituteInPlace Makefile \
            --replace-fail 'discarded-qualifiers' 'ignored-qualifiers'
        '';
        # Don't build userspace stuff
        postBuild = "";
        installPhase =
          builtins.replaceStrings [ "install -Dm755 library/libevdi.so" ] [ "#" ]
            prevAttrs.installPhase;
      });
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
  virtualbox =
    multiOverride virtualbox
      {
        inherit (final) virtualbox;
      }
      (prevAttrs: {
        makeFlags = prevAttrs.makeFlags ++ kernel.commonMakeFlags;
      });
  xpadneo = xpadneo.override {
    inherit (final) bluez;
  };
  zenpower = zenpower.overrideAttrs (prevAttrs: {
    makeFlags =
      prevAttrs.makeFlags
      ++ kernel.commonMakeFlags
      ++ [
        "KBUILD_CFLAGS="
      ];
  });
}
