{ fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
, ...
} @ args:
let
  major = "6.3";
  minor = "1";

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "d754a255474c3b1656c88f2eeb1b5c22573a386c";
    hash = "sha256-XPku8Dp8F50ol0qL16kJKFN8PhOSsXsDoSM/8N1zpqk=";
  };

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "f42a8524e0b0c0d21f66584a0295bdc6aacf79f6";
    hash = "sha256-QcplQbY/DdwNEcTmTRzcNPRl3bS3lApaaVnEnDy7A4k=";
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${major}.${minor}.tar.xz";
    sha256 = "eGIPtKfV4NsdTrjVscbiB7pdGVZO+mOWelm22vibPyo=";
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
).overrideAttrs (pa: { # bypasses https://github.com/NixOS/nixpkgs/issues/216529
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
