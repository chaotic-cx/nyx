{
  cachyConfig,
  kconfigToNix,
  config,
  configfile,
  updaterScript ? null,
  nyxUtils,
  lib,
  linuxManualConfig,
  stdenv,
  commonMakeFlags,
  # Weird injections
  kernelPatches ? [ ],
  features ? null,
  randstructSeed ? "",
}:
let
  version = cachyConfig.versions.linux.version;

  # linuxManualConfig depends dynamically of these
  enforcedConfigFeatures = config // {
    "CONFIG_MODULES" = "y";
    "CONFIG_RUST" = "y";
  };
in
(linuxManualConfig {
  inherit
    stdenv
    version
    features
    randstructSeed
    ;
  inherit (configfile) src;
  modDirVersion = lib.versions.pad 3 "${version}${cachyConfig.versions.suffix}";

  inherit configfile;
  config = enforcedConfigFeatures;
  allowImportFromDerivation = false;

  kernelPatches =
    kernelPatches
    ++ builtins.map (filename: {
      name = builtins.baseNameOf filename;
      patch = filename;
    }) configfile.passthru.kernelPatches;

  extraMeta = {
    maintainers = with lib.maintainers; [
      dr460nf1r3
      pedrohlc
    ];
    inherit (configfile.meta) platforms;
  };
}).overrideAttrs
  (prevAttrs: {
    postPatch = prevAttrs.postPatch + configfile.extraVerPatch;
    # mirrors https://github.com/NixOS/nixpkgs/blob/92fe0f1e295e816522f33fdcc3701b9b636bc474/pkgs/os-specific/linux/kernel/build.nix#L273
    makeFlags = [
      "O=$(buildRoot)"
      "--eval=undefine modules"
    ]
    ++ commonMakeFlags;
    # bypasses https://github.com/NixOS/nixpkgs/issues/216529
    passthru =
      prevAttrs.passthru
      // {
        inherit cachyConfig kconfigToNix commonMakeFlags;
        features = {
          efiBootStub = true;
          ia32Emulation = true;
          netfilterRPFilter = true;
        };
        isLTS = false;
        isZen = true;
        isHardened = cachyConfig.cpuSched == "hardened";
        isLibre = false;
        updateScript = null;
      }
      // nyxUtils.optionalAttr "updateScript" (updaterScript != null) updaterScript;
  })
