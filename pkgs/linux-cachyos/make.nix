{ stdenv
, taste
, configPath
, versions
, callPackage
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
, withHDR ? true
, withoutDebug ? false
, description ? "Linux EEVDF-BORE scheduler Kernel by CachyOS with other patches and improvements"
, withUpdateScript ? false
, zfs-source
, packagesExtend ? null
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
      withHDR
      withoutDebug
      description
      withUpdateScript;
  };

  # The three phases of the config
  # - First we apply the changes fromt their PKGBUILD using kconfig;
  # - Then we NIXify it (in the update-script);
  # - Last state is importing the NIXified version for building.
  linuxConfigOriginal = callPackage ./configfile-raw.nix {
    inherit cachyConfig stdenv kernel;
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
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      zfs_cachyos = prevAttrs.zfs_unstable.overrideAttrs (prevAttrs: {
        src = zfs-source;
        meta = prevAttrs.meta // { broken = false; };
        patches = [ ];
      });
    };

  basePackages = linuxPackagesFor kernel;
  packagesWithZFS = basePackages.extend addZFS;
  packagesWithExtend = if packagesExtend == null then packagesWithZFS else packagesWithZFS.extend (packagesExtend kernel);
  packagesWithoutZFS = removeAttrs packagesWithExtend [ "zfs" "zfs_2_1" "zfs_2_2" "zfs_unstable" ];
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithoutZFS;
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
