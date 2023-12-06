{ cachyConfig
, cachyConfigBake
, config
, configfile
, callPackage
, nyxUtils
, fetchFromGitHub
, fetchurl
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
  major = lib.versions.pad 2 version;

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${
      if version == "${major}.0" then major else version
    }.tar.xz";
    inherit (cachyConfig.versions.linux) hash;
  };
in
(linuxManualConfig {
  inherit stdenv src version features randstructSeed;
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
    broken = stdenv.system == "aarch64-linux";
  };
}
).overrideAttrs (prevAttrs: {
  # bypasses https://github.com/NixOS/nixpkgs/issues/216529
  passthru = prevAttrs.passthru // {
    inherit cachyConfig cachyConfigBake;
    features = {
      efiBootStub = true;
      ia32Emulation = true;
      iwlwifi = true;
      needsCifsUtils = true;
      netfilterRPFilter = true;
    };
  } // nyxUtils.optionalAttr "updateScript"
    (cachyConfig.taste == "linux-cachyos")
    (callPackage ./update.nix { });
})
