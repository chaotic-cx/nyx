# Hey Pedro, what is this?
# So, basically, the right way to build kernel modules is to build them with the exact toolchain,
# patched sources, and kconfig as the kernel itself. Nix is perfect for abstraction; kernel
# modules are in kernelspace and as the kernel doesn't have additional dependencies, we easily
# change the compiler in the “scope” and call it a day, right? Absolutely not! Some friends decided
# to add userspace applications as derivations within these kernel modules. E.g., nvidia-settings.
# Besides that, some things are warnings in one compiler and errors in the other, so let's have fun.
{
  final,
  nyxUtils,
  ...
}:
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
  cpupower = prevModules.cpupower.override {
    inherit (final) pciutils gettext which;
  };
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
  nvidia_x11_legacy470 = markBroken nvidia_x11_legacy470;
  nvidiaPackages = nvidiaPackages.extend (
    _finalNV: prevNV: with prevNV; {
      production = fixNoVideo production;
      stable = fixNoVideo stable;
      beta = fixNoVideo beta;
      vulkan_beta = fixNoVideo vulkan_beta;
      cachyos = final.nvidia_cachyos;
      latest = fixNoVideo latest;
      legacy_535 = fixNoVideo legacy_535;
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
  zenpower = zenpower.overrideAttrs (prevAttrs: {
    makeFlags =
      prevAttrs.makeFlags
      ++ kernel.commonMakeFlags
      ++ [
        "KBUILD_CFLAGS="
      ];
  });
}
