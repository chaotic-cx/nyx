{ argsOverride ? { }
, fetchFromGitHub
, fetchurl
, buildLinux
, lib
, linuxKernel
, super
, stdenv
, pkgs
, ...
} @ args:
let
  major = "6.2";
  minor = "11";

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    rev = "977c74a08501e82592bf6767c62a9c498a973951";
    hash = "sha256-K9zr0Xfdf8tOkn+REn/zA95pEt/mHB2n7mWpNJqnamc=";
  };

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    rev = "4e07e1b4ac296fbacd0e09889f6d29da8da4134c";
    hash = "sha256-dng4/rGmgHFGHICLk3P0jdB6BCzummCg7jKUovA4G9U=";
  };
in

buildLinux (args // rec {

  version = "${major}.${minor}";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${major}.${minor}.tar.xz";
    sha256 = "sha256-DSNnhOYLh8eVNTWusUjdnnc7Jkld+pxtaWFfVP4A3Uc=";
  };

  extraMeta = { maintainers = with lib; [ maintainers.dr460nf1r3 ]; };

  configfile = "${config-src}/linux-cachyos/config";
  defconfig = "${config-src}/linux-cachyos/config";
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
