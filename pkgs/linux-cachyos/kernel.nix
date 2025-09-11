{
  cachyConfig,
  kconfigToNix,
  config,
  configfile,
  callPackage,
  nyxUtils,
  lib,
  linuxManualConfig,
  stdenv,
  # Weird injections
  kernelPatches ? [ ],
  features ? null,
  randstructSeed ? "",
  # For tests
  kernelPackages,
  flakes,
  final,
}:
let
  inherit (cachyConfig.versions.linux) version;
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

  inherit config configfile;
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
    # bypasses https://github.com/NixOS/nixpkgs/issues/216529
    passthru =
      prevAttrs.passthru
      // {
        inherit cachyConfig kconfigToNix;
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
        tests = (prevAttrs.passthru.tests or { }) // {
          plymouth = import ./test.nix {
            inherit kernelPackages;
            inherit (flakes) nixpkgs;
            chaotic = flakes.self;
          } final;
        };
      }
      // nyxUtils.optionalAttr "updateScript" (cachyConfig.withUpdateScript != null) (
        callPackage ./update.nix {
          inherit (cachyConfig) withUpdateScript;
        }
      );
  })
