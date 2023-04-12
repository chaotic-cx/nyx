{ argsOverride ? { }
, fetchFromGitHub
, fetchurl
, kernelPatches
, lib
, stdenv
, pkgs
, ...
} @ args:
let
  major = "6.2";
  minor = "10";

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "170aecb143126d2bd2ceb1435c08a41573ee1a76";
    hash = "sha256-+XjguA+HPzIdPdEbROc1Wk3BCdBNl6r/nzvnqDmt8Os=";
  };

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "2b86f87806a40d0b8cd46c7032e81de902affd57";
    hash = "sha256-Gua1agYq9pw+TuAGJX1597o9BJvKhYANSkZKFQ7ohls=";
  };
in

(pkgs.linux_6_2.override { argsOverride = rec {
  version = "${major}.${minor}";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${major}.${minor}.tar.xz";
    sha256 = "sha256-V8Viw80nU/IyVJyrBcitdw7YSK6GQBYZx1gb3/rupP4=";
  };

  extraMeta = { maintainers = with lib; [ maintainers.dr460nf1r3 ]; };

  configfile = "${config-src}/linux-cachyos/config";

  kernelPatches =
    builtins.map
      (name: {
        inherit name;
        patch = name;
      })
      [
        "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
        "${patches-src}/${major}/misc/0001-Add-latency-priority-for-CFS-class.patch"
        "${patches-src}/${major}/sched/0001-bore-cachy.patch"
      ];

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
  };};
})
