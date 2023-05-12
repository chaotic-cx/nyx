{ fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
, runCommand
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

  readConfig = configfile: import (runCommand "config.nix" { } ''
    echo "{" > "$out"
    while IFS='=' read key val; do
      [ "x''${key#CONFIG_}" != "x$key" ] || continue
      no_firstquote="''${val#\"}";
      echo '  "'"$key"'" = "'"''${no_firstquote%\"}"'";' >> "$out"
    done < "${configfile}"
    echo "}" >> $out
  '').outPath;

  structuredExtraConfig = with lib.kernel; {
    EXPERT = no;
    WERROR = no;

    # Tick to 500hz
    HZ = freeform "500";
    HZ_500 = yes;
    HZ_1000 = no;

    # Disable MQ Deadline I/O scheduler
    MQ_IOSCHED_DEADLINE = lib.mkForce no;

    # Disable Kyber I/O scheduler
    MQ_IOSCHED_KYBER = lib.mkForce no;

    # Enabling full ticks
    CONTEXT_TRACKING_FORCE = option no;
    HZ_PERIODIC = no;
    NO_HZ_FULL_NODEF = option yes;
    NO_HZ_IDLE = no;

    # Enable O3
    CC_OPTIMIZE_FOR_PERFORMANCE = no;
    CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

    # Enable bbr2
    DEFAULT_BBR2 = yes;
    DEFAULT_CUBIC = option no;
    DEFAULT_TCP_CONG = freeform "bbr2";
    TCP_CONG_BBR2 = yes;
    TCP_CONG_CUBIC = lib.mkForce module;

    # Enable zram/zswap ZSTD compression
    MODULE_COMPRESS_ZSTD_LEVEL = option (freeform "9");
    MODULE_COMPRESS_ZSTD_ULTRA = option no;
    ZRAM_DEF_COMP = freeform "zstd";
    ZRAM_DEF_COMP_LZORLE = no;
    ZRAM_DEF_COMP_ZSTD = yes;
    ZSTD_COMPRESSION_LEVEL = freeform "19";
    ZSWAP_COMPRESSOR_DEFAULT = freeform "zstd";
    ZSWAP_COMPRESSOR_DEFAULT_LZO = no;
    ZSWAP_COMPRESSOR_DEFAULT_ZSTD = yes;
  };
in

(linuxManualConfig rec {
  inherit stdenv src;

  version = "${major}.${minor}-cachyos";
  modDirVersion = "${major}.${minor}";

  # just decoration because...
  allowImportFromDerivation = true;
  configfile = "${config-src}/linux-cachyos/config";

  # ...this one is being overwritten.
  config = readConfig configfile // structuredExtraConfig;

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
