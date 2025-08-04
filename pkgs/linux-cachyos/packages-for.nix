{
  stdenv,
  taste,
  configPath,
  versions,
  callPackage,
  linuxPackages,
  linuxPackagesFor,
  fetchFromGitHub,
  nyxUtils,
  lib,
  ogKernelConfigfile ? linuxPackages.kernel.passthru.configfile,
  withUpdateScript ? null,
  packagesExtend ? null,
  cachyOverride,
  # those are set in their PKGBUILDs
  kernelPatches ? { },
  basicCachy ? true,
  mArch ? null,
  cpuSched ? "cachyos",
  useLTO ? "none",
  ticksHz ? 500,
  tickRate ? "full",
  preempt ? "full",
  hugePages ? "always",
  withDAMON ? false,
  withNTSync ? true,
  withHDR ? true,
  withoutDebug ? false,
  description ? "Linux EEVDF-BORE scheduler Kernel by CachyOS with other patches and improvements",
  # For tests
  inputs,
}:

let
  cachyConfig = {
    inherit
      taste
      versions
      basicCachy
      mArch
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
      withUpdateScript
      ;
  };

  # The three phases of the config
  # - First we apply the changes fromt their PKGBUILD using kconfig;
  # - Then we NIXify it (in the update-script);
  # - Last state is importing the NIXified version for building.
  preparedConfigfile = callPackage ./prepare.nix {
    inherit
      cachyConfig
      stdenv
      kernel
      ogKernelConfigfile
      ;
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
    # For tests
    inherit (inputs) flakes final;
    kernelPackages = packagesWithRightPlatforms;
  };

  # CachyOS repeating stuff.
  addOurs = _finalAttrs: prevAttrs: {
    kernel_configfile = prevAttrs.kernel.configfile;
    zfs_cachyos = prevAttrs.zfs_2_3.overrideAttrs (prevAttrs: {
      src = fetchFromGitHub {
        owner = "cachyos";
        repo = "zfs";
        inherit (versions.zfs) rev hash;
      };
      meta = prevAttrs.meta // {
        broken = false;
      };
      patches = [ ];
      postPatch =
        builtins.replaceStrings [ "grep --quiet '^Linux-Maximum:" ] [ "# " ]
          prevAttrs.postPatch;
    });
    inherit cachyOverride;
  };

  basePackages = linuxPackagesFor kernel;
  packagesWithOurs = basePackages.extend addOurs;
  packagesWithExtend =
    if packagesExtend == null then
      packagesWithOurs
    else
      packagesWithOurs.extend (packagesExtend kernel);
  packagesWithRemovals = removeAttrs packagesWithExtend [
    "zfs"
    "zfs_2_1"
    "zfs_2_2"
    "zfs_2_3"
    "zfs_unstable"
    "lkrg"
    "drbd"
  ];
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithRemovals;
  packagesWithRightPlatforms = nyxUtils.setAttrsPlatforms supportedPlatforms packagesWithoutUpdateScript;

  supportedPlatforms = [
    (with lib.systems.inspect.patterns; isx86_64 // isLinux)
    "x86_64-linux"
  ];

  versionSuffix = "+C${nyxUtils.shorter versions.config.rev}+P${nyxUtils.shorter versions.patches.rev}";
in
packagesWithRightPlatforms
// {
  _description = "Kernel and modules for ${description}";
  _version = "${versions.linux.version}${versionSuffix}";
  inherit (basePackages) kernel; # This one still has the updateScript
}
