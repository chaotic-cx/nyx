{ fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
, ...
} @ args:
let
  major = "6.3";
  minor = "2";

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "2edd239e20f2fb852a0bc962f48c1d394acc0a3d";
    hash = "sha256-s2EYR77XuWM1O4IaoY7XdffGZTG1qWnJGofBQWn5LGc=";
  };

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "d2b92b14e924b821d9ec8dea3f947f46e061dd88";
    hash = "sha256-aDhYSryGU/S099EUPcX3O/r/JjIe7BbpkZonBM8ARfg=";
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${major}.${minor}.tar.xz";
    sha256 = "thLs8oLKP3mJ/22fOQgoM7fcLVIsuWmgUzTTYU6cUyg=";
  };
in

(linuxManualConfig rec {

  inherit stdenv src;

  version = "${major}.${minor}-cachyos";
  modDirVersion = "${major}.${minor}";

  allowImportFromDerivation = true;

  configfile = "${config-src}/linux-cachyos/config";

  kernelPatches =
    builtins.map
      (name: {
        inherit name;
        patch = name;
      })
      [
        "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
        "${patches-src}/${major}/sched/0001-bore-cachy.patch"
      ];

  extraMeta = { maintainers = with lib; [ maintainers.dr460nf1r3 ]; };
}
).overrideAttrs (pa: {
  # bypasses https://github.com/NixOS/nixpkgs/issues/216529
  passthru = pa.passthru // {
    features = {
      efiBootStub = true;
      ia32Emulation = true;
      iwlwifi = true;
      needsCifsUtils = true;
      netfilterRPFilter = true;
    };
  };
})
