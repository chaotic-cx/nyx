{ argsOverride ? { }
, buildLinux
, fetchFromGitHub
, fetchurl
, lib
, linuxKernel
, pkgs
, stdenv
, super
, ...
} @ args:
let
  major = "6.2";
  minor = "12";

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "ba60bf209c85851a28f076ad3ca3a39cb8f78142";
    hash = "sha256-hlVk9cYR+yeWtgEt6o4dy6r3OM4GeVTb7sjUbbsM8eU=";
  };

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "7f016bcf76d6879cbc8a1efbf5f4d55c581a4906";
    hash = "sha256-4dtnMKiBjFoJILuh8lbOPkk8u3cLrONGFOt5SlVz7/c=";
  };
in

buildLinux (args // rec {

  version = "${major}.${minor}-cachyos";
  modDirVersion = "${major}.${minor}";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${major}.${minor}.tar.xz";
    sha256 = "x+FGtSc3rfpMckv6Qb9HIcXuPPIgwHT7xg6z6mKwzMg=";
  };

  allowImportFromDerivation = true;

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
  };
})
