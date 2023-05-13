{ fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
, flex
, bison
, perl
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

  # There are some configurations setted by the PKGBUILD
  pkgbuildConfig = [
    # _cachy_config, defaults to "y"
    "-e CACHY"

    # _cpusched, defaults to "cachyos"
    "-e SCHED_BORE"

    # _HZ_ticks, defaults to "500"
    "-d HZ_300"
    "--set-val HZ 500"
    "-e HZ_500"

    # _nr_cpus, defaults to empty, which later set this
    "--set-val NR_CPUS 320"

    # _mq_deadline_disable, defaults to "y"
    "-d MQ_IOSCHED_DEADLINE"

    # _mq_deadline_disable, defaults to "y"
    "-d MQ_IOSCHED_KYBER"

    # _per_gov, defaults to "y"
    "-d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL"
    "-e CPU_FREQ_DEFAULT_GOV_PERFORMANCE"

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

    # _tcp_bbr2, defaults to "y"
    "-m TCP_CONG_CUBIC"
    "-d DEFAULT_CUBIC"
    "-e TCP_CONG_BBR2"
    "-e DEFAULT_BBR2"
    "--set-val DEFAULT_TCP_CONG bbr2"

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
  ];
in

(linuxManualConfig rec {
  inherit stdenv src;

  version = "${major}.${minor}-cachyos";
  modDirVersion = "${major}.${minor}";

  allowImportFromDerivation = true;
  configfile = stdenv.mkDerivation {
    inherit src;
    name = "linux-cachyos-config";
    nativeBuildInputs = [flex bison perl];

    preparePhase = ''
      cp "${config-src}/linux-cachyos/config" ".config"
    '';

    buildPhase = ''
      make defconfig
      cp "${config-src}/linux-cachyos/config" ".config"
      patchShebangs scripts/config
      scripts/config ${lib.concatStringsSep " " pkgbuildConfig}
    '';

    installPhase = ''
      cp .config $out
    '';
  };

  kernelPatches = builtins.map
    (filename: {
      name = builtins.baseNameOf filename;
      patch = filename;
    })
    [
      "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
      "${patches-src}/${major}/sched/0001-EEVDF.patch"
      "${patches-src}/${major}/sched/0001-bore-eevdf.patch"
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
