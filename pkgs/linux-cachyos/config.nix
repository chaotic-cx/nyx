{ lib, ... }:
with lib.kernel; {
  LOCALVERSION = freeform "-cachyos-bore";
  EXPERT = yes;
  WERROR = no;

  # Bore scheduler
  SCHED_BORE = yes;

  # Tick to 750hz
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

  # LRU config
  LRU_GEN = yes;
  LRU_GEN_ENABLED = yes;
  LRU_GEN_STATS = no;

  # Enable zram/zswap ZSTD compression
  MODULE_COMPRESS_ZSTD_LEVEL = option (freeform "9");
  MODULE_COMPRESS_ZSTD_ULTRA = option no;
  ZRAM_DEF_COMP = freeform "zstd";
  ZRAM_DEF_COMP_LZORLE = no;
  ZRAM_DEF_COMP_ZSTD = yes;
  ZSTD_COMPRESSION_LEVEL = freeform "19";
  ZSWAP_COMPRESSOR_DEFAULT = freeform "zstd";
  ZSWAP_COMPRESSOR_DEFAULT_LZ4 = no;
  ZSWAP_COMPRESSOR_DEFAULT_ZSTD = yes;


  # AMD P-state driver
  # Could cause issues in AMD Virtual machine
  X86_AMD_PSTATE = yes;

  PREEMPT_RCU = yes;
  TASKS_RCU = yes;
  UNINLINE_SPIN_UNLOCK = yes;
}
