{ cachyVersions
, cachyTaste
, fetchFromGitHub
, fetchurl
, lib
, stdenv
, flex
, bison
, perl
}:
let
  inherit (cachyVersions.linux) version;
  major = lib.versions.pad 2 version;

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    inherit (cachyVersions.config) rev hash;
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${
      if version == "${major}.0" then major else version
    }.tar.xz";
    inherit (cachyVersions.linux) hash;
  };

  # There are some configurations set by the PKGBUILD
  pkgbuildConfig = [
    # _cachy_config, defaults to "y"
    "-e CACHY"

    # _cpusched, defaults to "cachyos"
    "-e SCHED_BORE"

    # _nr_cpus, defaults to empty, which later set this
    "--set-val NR_CPUS 320"

    # _per_gov, defaults to empty [but PERSONAL CHANGE to "y"]
    "-d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL"
    "-e CPU_FREQ_DEFAULT_GOV_PERFORMANCE"

    # _tcp_bbr3, defaults to "y"
    "-m TCP_CONG_CUBIC"
    "-d DEFAULT_CUBIC"
    "-e TCP_CONG_BBR"
    "-e DEFAULT_BBR"
    "--set-str DEFAULT_TCP_CONG bbr"
    "-m NET_SCH_FQ_CODEL"
    "-e NET_SCH_FQ"
    "-d DEFAULT_FQ_CODEL"
    "-e DEFAULT_FQ"
    "--set-str DEFAULT_NET_SCH fq"

    # _HZ_ticks, defaults to "500"
    "-d HZ_300"
    "--set-val HZ 500"
    "-e HZ_500"

    # _tickrate defaults to "full"
    "-d HZ_PERIODIC"
    "-d NO_HZ_IDLE"
    "-d CONTEXT_TRACKING_FORCE"
    "-e NO_HZ_FULL_NODEF"
    "-e NO_HZ_FULL"
    "-e NO_HZ"
    "-e NO_HZ_COMMON"
    "-e CONTEXT_TRACKING"

    # _preempt, defaults to "full"
    "-e PREEMPT_BUILD"
    "-d PREEMPT_NONE"
    "-d PREEMPT_VOLUNTARY"
    "-e PREEMPT"
    "-e PREEMPT_COUNT"
    "-e PREEMPTION"
    "-e PREEMPT_DYNAMIC"

    # _cc_harder, defaults to "y"
    "-d CC_OPTIMIZE_FOR_PERFORMANCE"
    "-e CC_OPTIMIZE_FOR_PERFORMANCE_O3"

    # _lru_config, defaults to "standard"
    "-e LRU_GEN"
    "-e LRU_GEN_ENABLED"
    "-d LRU_GEN_STATS"

    # _vma_config, defaults to "standard"
    "-e PER_VMA_LOCK"
    "-d PER_VMA_LOCK_STATS"

    # _hugepage, defaults to "always"
    "-d TRANSPARENT_HUGEPAGE_MADVISE"
    "-e TRANSPARENT_HUGEPAGE_ALWAYS"

    #_use_auto_optimization, defaults to "y" [but GENERIC to ""]
  ];
in
stdenv.mkDerivation {
  inherit src;
  name = "linux-cachyos-config";
  nativeBuildInputs = [ flex bison perl ];

  preparePhase = ''
    cp "${config-src}/${cachyTaste}/config" ".config"
  '';

  buildPhase = ''
    make defconfig
    cp "${config-src}/${cachyTaste}/config" ".config"
    patchShebangs scripts/config
    scripts/config ${lib.concatStringsSep " " pkgbuildConfig}
  '';

  installPhase = ''
    cp .config $out
  '';
}
