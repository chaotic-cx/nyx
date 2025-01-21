{ stdenv
, taste
, configPath
, versions
, callPackage
, linuxPackages
, linuxPackagesFor
, fetchFromGitHub
, nyxUtils
, lib
, ogKernelConfigfile ? linuxPackages.kernel.passthru.configfile
, withUpdateScript ? null
, packagesExtend ? null
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
, withHDR ? true
, withoutDebug ? false
, description ? "Linux EEVDF-BORE scheduler Kernel by CachyOS with other patches and improvements"
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
      withHDR
      withoutDebug
      description
      withUpdateScript;
  };

  # The three phases of the config
  # - First we apply the changes fromt their PKGBUILD using kconfig;
  # - Then we NIXify it (in the update-script);
  # - Last state is importing the NIXified version for building.
  preparedConfigfile = callPackage ./prepare.nix {
    inherit cachyConfig stdenv kernel ogKernelConfigfile;
  };
  kconfigToNix = callPackage ./lib/kconfig-to-nix.nix {
    configfile = preparedConfigfile;
  };
  linuxConfigTransfomed = import configPath;

  kernel = callPackage ./kernel.nix {
    inherit cachyConfig stdenv kconfigToNix;
    kernelPatches = [ ];
    configfile = preparedConfigfile;
    config = linuxConfigTransfomed;
  };

  # CachyOS repeating stuff.
  addZFS = _finalAttrs: prevAttrs:
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      zfs_cachyos = prevAttrs.zfs_unstable.overrideAttrs (prevAttrs: {
        src = fetchFromGitHub {
          owner = "cachyos";
          repo = "zfs";
          inherit (versions.zfs) rev hash;
        };
        meta = prevAttrs.meta // { broken = false; };
        patches = [ ];
      });
    };

  basePackages = linuxPackagesFor kernel;
  packagesWithZFS = basePackages.extend addZFS;
  packagesWithExtend = if packagesExtend == null then packagesWithZFS else packagesWithZFS.extend (packagesExtend kernel);
  packagesWithRemovals = removeAttrs packagesWithExtend [ "zfs" "zfs_2_1" "zfs_2_2" "zfs_unstable" "lkrg" "drbd" ];
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithRemovals;
  packagesWithRightPlatforms = nyxUtils.setAttrsPlatforms supportedPlatforms packagesWithoutUpdateScript;

  supportedPlatforms = [ (with lib.systems.inspect.patterns; isx86_64 // isLinux) "x86_64-linux" ];

  versionSuffix = "+C${nyxUtils.shorter versions.config.rev}+P${nyxUtils.shorter versions.patches.rev}";
in
packagesWithRightPlatforms // {
  _description = "Kernel and modules for ${description}";
  _version = "${versions.linux.version}${versionSuffix}";
  inherit (basePackages) kernel; # This one still has the updateScript
}
