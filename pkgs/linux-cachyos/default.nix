{ cachyVersions
, cachyConfig
, linux_cachyos-configfile_raw
, callPackage
, fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
}:
let
  inherit (cachyVersions.linux) version;
  major = lib.versions.pad 2 version;

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    inherit (cachyVersions.patches) rev hash;
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${
      if version == "${major}.0" then major else version
    }.tar.xz";
    inherit (cachyVersions.linux) hash;
  };
in

(linuxManualConfig rec {
  inherit stdenv src version;
  modDirVersion = lib.versions.pad 3 "${version}${cachyVersions.suffix}";

  config = cachyConfig;
  configfile = linux_cachyos-configfile_raw;
  allowImportFromDerivation = false;

  kernelPatches = builtins.map
    (filename: {
      name = builtins.baseNameOf filename;
      patch = filename;
    })
    [
      "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
      "${patches-src}/${major}/sched/0001-EEVDF-cachy.patch"
      "${patches-src}/${major}/sched/0001-bore-eevdf.patch"
      "${patches-src}/${major}/misc/0001-Add-extra-version-CachyOS.patch"
      "${patches-src}/${major}/misc/0001-bcachefs.patch"
    ];

  extraMeta = { maintainers = with lib.maintainers; [ dr460nf1r3 pedrohlc ]; };
}
).overrideAttrs (prevAttrs: {
  # bypasses https://github.com/NixOS/nixpkgs/issues/216529
  passthru = prevAttrs.passthru // {
    inherit cachyVersions;
    features = {
      efiBootStub = true;
      ia32Emulation = true;
      iwlwifi = true;
      needsCifsUtils = true;
      netfilterRPFilter = true;
    };
    updateScript = callPackage ./update.nix { };
  };
  meta = prevAttrs.meta // {
    # at the time of this writing, they don't have config files for aarch64
    broken = stdenv.system == "aarch64-linux";
  };
})
