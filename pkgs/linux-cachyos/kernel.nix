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

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    inherit (cachyConfig.versions.patches) rev hash;
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${
      if version == "${major}.0" then major else version
    }.tar.xz";
    inherit (cachyConfig.versions.linux) hash;
  };

  schedPatch =
    if cachyConfig.cpuSched == "cachyos" || cachyConfig.cpuSched == "hardened" then
      "bore-cachy"
    else throw "Unsupported cachyos _cpu_sched";
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
    ([ "${patches-src}/${major}/all/0001-cachyos-base-all.patch" ]
      ++ lib.optional (cachyConfig.cpuSched != "eevdf") "${patches-src}/${major}/sched/0001-${schedPatch}.patch"
      ++ lib.optional (cachyConfig.cpuSched != "hardened") "${patches-src}/${major}/misc/0001-hardened.patch"
      ++ [ "${patches-src}/${major}/misc/0001-Add-extra-version-CachyOS.patch" ]
      ++ lib.optional cachyConfig.withBCacheFS "${patches-src}/${major}/misc/0001-bcachefs.patch"
    );

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
