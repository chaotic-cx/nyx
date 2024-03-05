{ stdenv
, taste
, configPath
, versions
, callPackage
, fetchFromGitHub
, linuxPackagesFor
, nyxUtils
, lib
  # those are set in their PKGBUILDs
, kernelPatches ? { }
, basicCachy ? true
, cpuSched ? "cachyos"
, useLTO ? "none"
, ticksHz ? 500
, tickRate ? "full"
, preempt ? "full"
, hugePages ? "always"
, withDAMON ? false
, withNTSync ? true
, withBCacheFSPatch ? false
, withHDRPatch ? true
, withoutDebug ? false
, description ? "Linux EEVDF-BORE scheduler Kernel by CachyOS with other patches and improvements"
, withUpdateScript ? false
}:

let
  cachyConfig = {
    inherit taste versions basicCachy
      cpuSched
      useLTO
      ticksHz
      tickRate
      preempt
      hugePages
      withDAMON
      withNTSync
      withBCacheFSPatch
      withHDRPatch
      withoutDebug
      description
      withUpdateScript;
  };

  # The three phases of the config
  # - First we apply the changes fromt their PKGBUILD using kconfig;
  # - Then we NIXify it (in the update-script);
  # - Last state is importing the NIXified version for building.
  linuxConfigOriginal = callPackage ./configfile-raw.nix {
    inherit cachyConfig stdenv;
  };
  linuxConfigTransformable = callPackage ./configfile-bake.nix {
    configfile = linuxConfigOriginal;
  };
  linuxConfigTransfomed = import configPath;

  kernel = callPackage ./kernel.nix {
    inherit cachyConfig stdenv;
    kernelPatches = [ ];
    configfile = linuxConfigOriginal;
    config = linuxConfigTransfomed;
    cachyConfigBake = linuxConfigTransformable;
  };

  # CachyOS repeating stuff.
  addZFS = _finalAttrs: prevAttrs:
    let
      zfs = prevAttrs.zfs_unstable.overrideAttrs (prevAttrs: {
        src =
          fetchFromGitHub {
            owner = "cachyos";
            repo = "zfs";
            inherit (versions.zfs) rev hash;
          };
        meta = prevAttrs.meta // { broken = false; };
        patches = [ ];
      });
    in
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      inherit zfs;
      zfs_2_2 = zfs;
      zfs_unstable = zfs;
    };

  basePackages = linuxPackagesFor kernel;
  packagesWithZFS = basePackages.extend addZFS;
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithZFS;
  packagesWithRightPlatforms = nyxUtils.setAttrsPlatforms supportedPlatforms packagesWithoutUpdateScript;

  supportedPlatforms = [ (with lib.systems.inspect.patterns; isx86_64 // isLinux) "x86_64-linux" ];

  versionSuffix = "+C${nyxUtils.shorter versions.config.rev}+P${nyxUtils.shorter versions.patches.rev}"
    + lib.strings.optionalString withBCacheFSPatch "+bcachefs";
in
packagesWithRightPlatforms // {
  _description = "Kernel and modules for ${description}";
  _version = "${versions.linux.version}${versionSuffix}";
  inherit (basePackages) kernel; # This one still has the updateScript
}
