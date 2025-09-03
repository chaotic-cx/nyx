{
  cachyConfig,
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  kernel,
  ogKernelConfigfile,
  commonMakeFlags,
}:
let
  inherit (cachyConfig.versions.linux) version;
  majorMinor = lib.versions.majorMinor version;

  patches-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "kernel-patches";
    inherit (cachyConfig.versions.patches) rev hash;
  };

  config-src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "linux-cachyos";
    inherit (cachyConfig.versions.config) rev hash;
  };

  src =
    if cachyConfig.taste == "linux-cachyos-rc" then
      fetchurl {
        url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
        inherit (cachyConfig.versions.linux) hash;
      }
    else
      fetchurl {
        url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${
          if version == "${majorMinor}.0" then majorMinor else version
        }.tar.xz";
        inherit (cachyConfig.versions.linux) hash;
      };

  schedPatches =
    if cachyConfig.cpuSched == "eevdf" then
      [ ]
    else if cachyConfig.cpuSched == "hardened" then
      [ ] # BORE disabled in CachyOS/linux-cachyos/commit/4ffae8ab9947f35495dfa7b62b7a22f023488dfb
    else if (cachyConfig.cpuSched == "cachyos" || cachyConfig.cpuSched == "sched-ext") then
      lib.optionals (lib.strings.versionOlder majorMinor "6.12") [
        "${patches-src}/${majorMinor}/sched/0001-sched-ext.patch"
      ]
      ++ lib.optionals (cachyConfig.cpuSched == "cachyos" && version != "6.17-rc1") [
        "${patches-src}/${majorMinor}/sched/0001-bore-cachy.patch"
      ]
    else
      throw "Unsupported cachyos _cpu_sched=${toString cachyConfig.cpuSched}";

  patches = [
    "${patches-src}/${majorMinor}/all/0001-cachyos-base-all.patch"
  ]
  ++ schedPatches
  ++ lib.optional (
    cachyConfig.cpuSched == "hardened"
  ) "${patches-src}/${majorMinor}/misc/0001-hardened.patch";

  # There are some configurations set by the PKGBUILD
  pkgbuildConfig =
    with cachyConfig;
    basicCachyConfig
    ++ mArchConfig
    ++ cpuSchedConfig
    ++ [
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

      # Nixpkgs don't support this
      "-d CONFIG_SECURITY_TOMOYO"
    ]
    ++ ltoConfig
    ++ ticksHzConfig
    ++ tickRateConfig
    ++ preemptConfig
    ++ [
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
    ]
    ++ hugePagesConfig
    ++ damonConfig
    ++ ntSyncConfig
    ++ hdrConfig
    ++ disableDebug;

  # _cachy_config, defaults to "y"
  basicCachyConfig = lib.optional cachyConfig.basicCachy "-e CACHY";

  # _processor_opt config, defaults to ""
  mArchConfig =
    if cachyConfig.mArch == null then
      [ ]
    else if cachyConfig.mArch == "NATIVE" then
      [
        "-d GENERIC_CPU"
        "-d MZEN4"
        "-e X86_NATIVE_CPU"
      ]
    else if cachyConfig.mArch == "ZEN4" then
      [
        "-d GENERIC_CPU"
        "-e MZEN4"
        "-d X86_NATIVE_CPU"
      ]
    else if builtins.match "GENERIC_V[1-4]" cachyConfig.mArch != null then
      let
        v = lib.strings.removePrefix "GENERIC_V" cachyConfig.mArch;
      in
      [
        "-e GENERIC_CPU"
        "-d MZEN4"
        "-d X86_NATIVE_CPU"
        "--set-val X86_64_VERSION ${v}"
      ]
    else
      throw "Unsuppoted cachyos mArch";

  # _cpusched, defaults to "cachyos"
  cpuSchedConfig =
    if cachyConfig.cpuSched == "eevdf" then
      [ ]
    else if cachyConfig.cpuSched == "hardened" then
      [ "-e SCHED_BORE" ]
    else if cachyConfig.cpuSched == "sched-ext" then
      [ "-e SCHED_CLASS_EXT" ]
    else if cachyConfig.cpuSched == "cachyos" then
      [
        "-e SCHED_BORE"
        "-e SCHED_CLASS_EXT"
      ]
    else
      throw "Unsupported cachyos scheduler";

  # _HZ_ticks, defaults to "500"
  ticksHzConfig =
    if cachyConfig.ticksHz == 300 then
      [
        "-e HZ_300"
        "--set-val HZ 300"
      ]
    else
      [
        "-d HZ_300"
        "--set-val HZ ${toString cachyConfig.ticksHz}"
        "-e HZ_${toString cachyConfig.ticksHz}"
      ];

  # _use_llvm_lto, defaults to "none"
  ltoConfig =
    assert (cachyConfig.useLTO == "none" || stdenv.cc.isClang);
    if cachyConfig.useLTO == "thin" then
      [
        "-e LTO"
        "-e LTO_CLANG"
        "-e ARCH_SUPPORTS_LTO_CLANG"
        "-e ARCH_SUPPORTS_LTO_CLANG_THIN"
        "-d LTO_NONE"
        "-e HAS_LTO_CLANG"
        "-d LTO_CLANG_FULL"
        "-e LTO_CLANG_THIN"
        "-e HAVE_GCC_PLUGINS"
      ]
    else if cachyConfig.useLTO == "full" then
      [
        "-e LTO"
        "-e LTO_CLANG"
        "-e ARCH_SUPPORTS_LTO_CLANG"
        "-e ARCH_SUPPORTS_LTO_CLANG_THIN"
        "-d LTO_NONE"
        "-e HAS_LTO_CLANG"
        "-e LTO_CLANG_FULL"
        "-d LTO_CLANG_THIN"
        "-e HAVE_GCC_PLUGINS"
      ]
    else if cachyConfig.useLTO == "none" then
      [ ]
    else
      throw "Unsupported cachyos _use_llvm_lto";

  # _tickrate defaults to "full"
  tickRateConfig =
    if cachyConfig.tickRate == "idle" then
      [
        "-d HZ_PERIODIC"
        "-d NO_HZ_FULL"
        "-e NO_HZ_IDLE"
        "-e NO_HZ"
        "-e NO_HZ_COMMON"
      ]
    else if cachyConfig.tickRate == "full" then
      [
        "-d HZ_PERIODIC"
        "-d NO_HZ_IDLE"
        "-d CONTEXT_TRACKING_FORCE"
        "-e NO_HZ_FULL_NODEF"
        "-e NO_HZ_FULL"
        "-e NO_HZ"
        "-e NO_HZ_COMMON"
        "-e CONTEXT_TRACKING"
      ]
    else
      throw "Unsupported cachyos _tickrate";

  # _preempt, defaults to "full"
  preemptConfig =
    if cachyConfig.preempt == "full" then
      [
        "-e PREEMPT_BUILD"
        "-d PREEMPT_NONE"
        "-d PREEMPT_VOLUNTARY"
        "-e PREEMPT"
        "-e PREEMPT_COUNT"
        "-e PREEMPTION"
        "-e PREEMPT_DYNAMIC"
      ]
    else if cachyConfig.preempt == "server" then
      [
        "-e PREEMPT_NONE_BUILD"
        "-e PREEMPT_NONE"
        "-d PREEMPT_VOLUNTARY"
        "-d PREEMPT"
        "-d PREEMPTION"
        "-d PREEMPT_DYNAMIC"
      ]
    else
      throw "Unsupported cachyos _preempt";

  # _hugepage, defaults to "always"
  hugePagesConfig =
    if cachyConfig.hugePages == "always" then
      [
        "-d TRANSPARENT_HUGEPAGE_MADVISE"
        "-e TRANSPARENT_HUGEPAGE_ALWAYS"
      ]
    else if cachyConfig.hugePages == "madvise" then
      [
        "-d TRANSPARENT_HUGEPAGE_ALWAYS"
        "-e TRANSPARENT_HUGEPAGE_MADVISE"
      ]
    else
      throw "Unsupported cachyos _hugepage";

  # _damon, defaults to empty
  damonConfig = lib.optionals cachyConfig.withDAMON [
    "-e DAMON"
    "-e DAMON_VADDR"
    "-e DAMON_DBGFS"
    "-e DAMON_SYSFS"
    "-e DAMON_PADDR"
    "-e DAMON_RECLAIM"
    "-e DAMON_LRU_SORT"
  ];

  # _ntsync, defaults to empty
  ntSyncConfig = lib.optionals cachyConfig.withNTSync [ "-m NTSYNC" ];

  # custom made
  hdrConfig = lib.optionals cachyConfig.withHDR [ "-e AMD_PRIVATE_COLOR" ];

  # https://github.com/CachyOS/linux-cachyos/issues/187
  disableDebug =
    lib.optionals
      (
        cachyConfig.withoutDebug && cachyConfig.cpuSched != "sched-ext" && cachyConfig.cpuSched != "cachyos"
      )
      [
        "-d DEBUG_INFO"
        "-d DEBUG_INFO_BTF"
        "-d DEBUG_INFO_DWARF4"
        "-d DEBUG_INFO_DWARF5"
        "-d PAHOLE_HAS_SPLIT_BTF"
        "-d DEBUG_INFO_BTF_MODULES"
        "-d SLUB_DEBUG"
        "-d PM_DEBUG"
        "-d PM_ADVANCED_DEBUG"
        "-d PM_SLEEP_DEBUG"
        "-d ACPI_DEBUG"
        "-d SCHED_DEBUG"
        "-d LATENCYTOP"
        "-d DEBUG_PREEMPT"
      ];
in
stdenv.mkDerivation (finalAttrs: {
  inherit src patches;
  name = "linux-cachyos-config";
  nativeBuildInputs = kernel.nativeBuildInputs ++ kernel.buildInputs;

  makeFlags = commonMakeFlags;

  postPhase = ''
    ${finalAttrs.passthru.extraVerPatch}
  '';

  buildPhase = ''
    runHook preBuild

    cp "${config-src}/${cachyConfig.taste}/config" ".config"
    make $makeFlags olddefconfig
    patchShebangs scripts/config
    scripts/config ${lib.concatStringsSep " " pkgbuildConfig}
    make $makeFlags olddefconfig

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp .config $out

    runHook postInstall
  '';

  meta = ogKernelConfigfile.meta // {
    # at the time of this writing, they don't have config files for aarch64
    platforms = [ "x86_64-linux" ];
  };

  passthru = {
    inherit cachyConfig commonMakeFlags stdenv;
    kernelPatches = patches;
    extraVerPatch = ''
      sed -Ei"" 's/EXTRAVERSION = ?(.*)$/EXTRAVERSION = \1${cachyConfig.versions.suffix}/g' Makefile
    '';
  };
})
