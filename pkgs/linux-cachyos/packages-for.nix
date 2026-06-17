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
  buildPackages,
  ogKernelConfigfile ? linuxPackages.kernel.passthru.configfile,
  withUpdateScript ? null,
  packagesExtend ? null,
  cachyOverride,
  extraMakeFlags ? [ ],
  zfsOverride ? { },
  cachyVars,
  withHDR ? true,
  withoutDebug ? false,
  description ? "Linux EEVDF-BORE scheduler Kernel by CachyOS with other patches and improvements",
  # For flakes
  inputs,
}:

let
  cachyConfig = {
    inherit
      taste
      versions
      cachyVars
      withHDR
      withoutDebug
      description
      withUpdateScript
      ;

    basicCachy = yesOrNo cachyVars."_cachy_config";
    mArch = nullIfEmpty cachyVars."_processor_opt";
    cpuSched = cachyVars."_cpusched";
    ccHarder = yesOrNo cachyVars."_cc_harder";
    perGov = yesOrNo cachyVars."_per_gov";
    tcpBBR3 = yesOrNo cachyVars."_tcp_bbr3";
    useLTO = cachyVars."_use_llvm_lto";
    useKCFI = yesOrNo cachyVars."_use_kcfi";
    ticksHz = lib.strings.toInt cachyVars."_HZ_ticks";
    tickRate = cachyVars."_tickrate";
    preempt = cachyVars."_preempt";
    hugePages = cachyVars."_hugepage";
    autoFDO = yesOrNo (cachyVars."_autofdo" or "no");
    propeller = yesOrNo (cachyVars."_propeller" or "no");
  };

  yesOrNo =
    str:
    if str == "yes" then
      true
    else if str == "no" then
      false
    else
      throw "Unsupported yes/no value";

  nullIfEmpty = str: if str == "" then null else str;

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
      commonMakeFlags
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

  commonMakeFlags = import "${inputs.flakes.nixpkgs}/pkgs/os-specific/linux/kernel/common-flags.nix" {
    inherit
      lib
      stdenv
      buildPackages
      extraMakeFlags
      ;
  };

  # CachyOS repeating stuff.
  addOurs = finalAttrs: prevAttrs: {
    kernel_configfile = prevAttrs.kernel.configfile;
    zfs_cachyos =
      (finalAttrs.callPackage "${inputs.flakes.nixpkgs}/pkgs/os-specific/linux/zfs/generic.nix"
        zfsOverride
        {
          kernelModuleAttribute = "zfs_cachyos";
          kernelMinSupportedMajorMinor = "1.0";
          kernelMaxSupportedMajorMinor = "99.99";
          enableUnsupportedExperimentalKernel = true;
          inherit (prevAttrs.zfs_2_4) version;
          tests = { };
          maintainers = with lib.maintainers; [
            pedrohlc
          ];
          hash = "";
          extraPatches = [ ];
        }
      ).overrideAttrs
        (prevAttrs: {
          src = fetchFromGitHub {
            owner = "cachyos";
            repo = "zfs";
            inherit (versions.zfs) rev hash;
          };
          postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
        });
    nvidiaPackages = prevAttrs.nvidiaPackages.extend (
      _finalNV: _prevNV: {
        cachyos =
          let
            suffix = lib.strings.removePrefix "linux-cachyos" taste;
            attrName = "nvidia_cachyos${suffix}";
          in
          inputs.final.${attrName};
      }
    );
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
    "zfs_2_4"
    "zfs_unstable"
    "lkrg"
    "drbd"
    # these kernelPackages.* are now pkgs.*
    "system76-power"
    "system76-scheduler"
    "perf"
  ];
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithRemovals;
  packagesWithRightPlatforms = nyxUtils.setAttrsPlatforms supportedPlatforms packagesWithoutUpdateScript;

  supportedPlatforms = [
    (with lib.systems.inspect.patterns; isx86_64 // isLinux)
    (with lib.systems.inspect.patterns; isx86 // isLinux)
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
