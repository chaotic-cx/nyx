{ cachyVersions
, callPackage
, fetchFromGitHub
, fetchurl
, lib
, linuxManualConfig
, stdenv
, flex
, bison
, perl
, ...
}:
let
  inherit (cachyVersions.linux) version;
  major = lib.versions.pad 2 version;

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    inherit (cachyVersions.config) rev hash;
  };

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    inherit (cachyVersions.patches) rev hash;
  };

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
    inherit (cachyVersions.linux) hash;
  };

  # There are some configurations set by the PKGBUILD
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
  inherit stdenv src version;
  modDirVersion = lib.versions.pad 3 "${version}${cachyVersions.suffix}";

  allowImportFromDerivation = true;
  configfile = stdenv.mkDerivation {
    inherit src;
    name = "linux-cachyos-config";
    nativeBuildInputs = [ flex bison perl ];

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
    ([
      "${patches-src}/${major}/all/0001-cachyos-base-all.patch"
      "${patches-src}/${major}/sched/0001-EEVDF.patch"
      "${patches-src}/${major}/sched/0001-bore-eevdf.patch"
      "${patches-src}/${major}/misc/0001-Add-extra-version-CachyOS.patch"
    ];

  extraMeta = { maintainers = with lib; [ maintainers.dr460nf1r3 ]; };
}
).overrideAttrs (pa: {
  # bypasses https://github.com/NixOS/nixpkgs/issues/216529
  passthru = pa.passthru // {
    inherit cachyVersions;
    features = {
      efiBootStub = true;
      ia32Emulation = true;
      iwlwifi = true;
      needsCifsUtils = true;
      netfilterRPFilter = true;
    };
    updateScript = callPackage ./update.nix { };
  };
})
