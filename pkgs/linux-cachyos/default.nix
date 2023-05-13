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

  # There are some configurations setted by the PKGBUILD
  structuredExtraConfig = with lib.kernel; {
    # _cachy_config, defaults to "y"
    CONFIG_CACHY = yes;

    # _cpusched, defaults to "cachyos"
    CONFIG_SCHED_BORE = yes;

    # _HZ_ticks, defaults to "500"
    CONFIG_HZ_300 = no;
    CONFIG_HZ = freeform "500";
    CONFIG_HZ_500 = yes;

    # _nr_cpus, defaults to empty, which later set this
    CONFIG_NR_CPUS = freeform "320";

    # _mq_deadline_disable, defaults to "y"
    CONFIG_MQ_IOSCHED_DEADLINE = no;

    # _mq_deadline_disable, defaults to "y"
    CONFIG_MQ_IOSCHED_KYBER = no;

    # _per_gov, defaults to "y"
    CONFIG_CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = no;
    CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE = yes;

    # _tickrate defaults to "full"
    CONFIG_HZ_PERIODIC = no;
    CONFIG_NO_HZ_IDLE = no;
    CONFIG_CONTEXT_TRACKING_FORCE = no;
    CONFIG_NO_HZ_FULL_NODEF = yes;
    CONFIG_NO_HZ_FULL = yes;
    CONFIG_NO_HZ = yes;
    CONFIG_NO_HZ_COMMON = yes;
    CONFIG_CONTEXT_TRACKING = yes;

    # _preempt, defaults to "full"
    CONFIG_PREEMPT_BUILD = yes;
    CONFIG_PREEMPT_NONE = no;
    CONFIG_PREEMPT_VOLUNTARY = no;
    CONFIG_PREEMPT = yes;
    CONFIG_PREEMPT_COUNT = yes;
    CONFIG_PREEMPTION = yes;
    CONFIG_PREEMPT_DYNAMIC = yes;

    # _cc_harder, defaults to "y"
    CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE = no;
    CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3 = yes;

    # _tcp_bbr2, defaults to "y"
    CONFIG_TCP_CONG_CUBIC = module;
    CONFIG_DEFAULT_CUBIC = no;
    CONFIG_TCP_CONG_BBR2 = yes;
    CONFIG_DEFAULT_BBR2 = yes;
    CONFIG_DEFAULT_TCP_CONG = freeform "bbr2";

    # _lru_config, defaults to "standard"
    CONFIG_LRU_GEN = yes;
    CONFIG_LRU_GEN_ENABLED = yes;
    CONFIG_LRU_GEN_STATS = no;

    # _vma_config, defaults to "standard"
    CONFIG_PER_VMA_LOCK = yes;
    CONFIG_PER_VMA_LOCK_STATS = no;

    # _hugepage, defaults to "always"
    CONFIG_TRANSPARENT_HUGEPAGE_MADVISE = no;
    CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS = yes;
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
