{ cachyConfig
, kconfigToNix
, config
, configfile
, callPackage
, nyxUtils
, lib
, linuxManualConfig
, stdenv
  # Weird injections
, kernelPatches ? [ ]
, features ? null
, randstructSeed ? ""
}@inputs:
let
  inherit (cachyConfig.versions.linux) version;
in
(linuxManualConfig {
  inherit stdenv version features randstructSeed;
  inherit (configfile) src;
  modDirVersion = lib.versions.pad 3 "${version}${cachyConfig.versions.suffix}";

  inherit config configfile;
  allowImportFromDerivation = false;

  kernelPatches = inputs.kernelPatches ++ builtins.map
    (filename: {
      name = builtins.baseNameOf filename;
      patch = filename;
    })
    configfile.passthru.kernelPatches;

  extraMeta = {
    maintainers = with lib.maintainers; [ dr460nf1r3 pedrohlc ];
    # at the time of this writing, they don't have config files for aarch64
    platforms = [ "x86_64-linux" ];
  };
}
).overrideAttrs (prevAttrs: {
  # bypasses https://github.com/NixOS/nixpkgs/issues/216529
  passthru = prevAttrs.passthru // {
    inherit cachyConfig kconfigToNix;
    features = {
      efiBootStub = true;
      ia32Emulation = true;
      netfilterRPFilter = true;
    };
    updateScript = null;
  } // nyxUtils.optionalAttr "updateScript"
    cachyConfig.withUpdateScript
    (callPackage ./update.nix { });
})
