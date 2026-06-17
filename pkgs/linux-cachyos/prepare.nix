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

  # Use GitHub releases tarball (PR #700) if tagrel is provided
  src =
    if cachyConfig.versions.linux ? tagrel then
      let
        inherit (cachyConfig.versions.linux) tagrel;
        srctag = "cachyos-${version}-${toString tagrel}";
      in
      fetchurl {
        url = "https://github.com/CachyOS/linux/releases/download/${srctag}/${srctag}.tar.gz";
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
    if cachyConfig.cpuSched == "bore" then
      [ "${patches-src}/${majorMinor}/sched/0001-bore-cachy.patch" ]
    else if cachyConfig.cpuSched == "bmq" then
      [ "${patches-src}/${majorMinor}/sched/0001-prjc-cachy.patch" ]
    else if (cachyConfig.cpuSched == "hardened") then
      [
        "${patches-src}/${majorMinor}/sched/0001-bore-cachy.patch"
        "${patches-src}/${majorMinor}/misc/0001-hardened.patch"
      ]
    else if (cachyConfig.cpuSched == "rt-bore") then
      [
        "${patches-src}/${majorMinor}/sched/0001-bore-cachy.patch"
        "${patches-src}/${majorMinor}/misc/0001-rt-i915.patch"
      ]
    else if (cachyConfig.cpuSched == "rt") then
      [ "${patches-src}/${majorMinor}/misc/0001-rt-i915.patch" ]
    else
      [ ];

  # If tagrel is provided, base patch is in the GitHub release tarball
  patches =
    lib.optionals (!(cachyConfig.versions.linux ? tagrel)) [
      "${patches-src}/${majorMinor}/all/0001-cachyos-base-all.patch"
    ]
    ++ schedPatches;

  # There are some configurations set by the PKGBUILD
  pkgbuildConfig =
    with cachyConfig;
    basicCachyConfig
    ++ mArchConfig
    ++ cpuSchedConfig
    ++ perGovConfig
    ++ tcpBBR3Config
    ++ kcfiConfig
    ++ ltoConfig
    ++ ticksHzConfig
    ++ tickRateConfig
    ++ preemptConfig
    ++ ccHarderConfig
    ++ hugePagesConfig
    ++ qrCodePanicConfig
    ++ autoFDOConfig
    ++ propellerConfig
    ++ hdrConfig
    ++ disableDebug
    ++ [
      # Nixpkgs don't support this
      "-d CONFIG_SECURITY_TOMOYO"
    ];

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
      throw "Unsupported cachyos mArch: ${cachyConfig.mArch}";

  # _cpusched, defaults to "cachyos"
  cpuSchedConfig =
    if cachyConfig.cpuSched == "cachyos" then
      [
        "-e SCHED_BORE"
        "-e SCHED_CLASS_EXT"
      ]
    else if cachyConfig.cpuSched == "bore" then
      [ "-e SCHED_BORE" ]
    else if cachyConfig.cpuSched == "hardened" then
      [ "-e SCHED_BORE" ]
    else if cachyConfig.cpuSched == "bmq" then
      [
        "-e SCHED_ALT"
        "-e SCHED_BMQ"
      ]
    else if cachyConfig.cpuSched == "eevdf" then
      [ ]
    else if cachyConfig.cpuSched == "rt" then
      [ "-e PREEMPT_RT" ]
    else if cachyConfig.cpuSched == "rt-bore" then
      [
        "-e SCHED_BORE"
        "-e PREEMPT_RT"
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
      [ "-e LTO_CLANG_THIN" ]
    else if cachyConfig.useLTO == "thin-dist" then
      [ "-e LTO_CLANG_THIN_DIST" ]
    else if cachyConfig.useLTO == "full" then
      [ "-e LTO_CLANG_FULL" ]
    else if cachyConfig.useLTO == "none" then
      [ "-e LTO_NONE" ]
    else
      throw "Unsupported cachyos _use_llvm_lto";

  qrCodePanicConfig =
    if cachyConfig.useLTO == "none" then
      [
        "--set-str DRM_PANIC_SCREEN qr_code"
        "-e DRM_PANIC_SCREEN_QR_CODE"
        "--set-str DRM_PANIC_SCREEN_QR_CODE_URL https://panic.archlinux.org/panic_report#"
        "--set-val CONFIG_DRM_PANIC_SCREEN_QR_VERSION 40"
      ]
    else
      [ ];

  # _tickrate defaults to "full"
  tickRateConfig =
    if cachyConfig.tickRate == "periodic" then
      [
        "-d NO_HZ_IDLE"
        "-d NO_HZ_FULL"
        "-d NO_HZ"
        "-d NO_HZ_COMMON"
        "-e HZ_PERIODIC"
      ]
    else if cachyConfig.tickRate == "idle" then
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
        "-e PREEMPT"
        "-d PREEMPT_LAZY"
      ]
    else if cachyConfig.preempt == "lazy" then
      [
        "-d PREEMPT"
        "-e PREEMP_LAZY"
      ]
    else
      throw "Unsupported cachyos _preempt";

  kcfiConfig =
    if cachyConfig.useKCFI then
      [
        "-e ARCH_SUPPORTS_CFI_CLANG"
        "-e CFI_CLANG"
        "-e CFI_AUTO_DEFAULT"
      ]
    else
      [ ];

  perGovConfig =
    if cachyConfig.perGov then
      [
        "-d CPU_FREQ_DEFAULT_GOV_SCHEDUTIL"
        "-e CPU_FREQ_DEFAULT_GOV_PERFORMANCE"
      ]
    else
      [ ];

  tcpBBR3Config =
    if cachyConfig.tcpBBR3 then
      [
        "-m TCP_CONG_CUBIC"
        "-d DEFAULT_CUBIC"
        "-e TCP_CONG_BBR"
        "-e DEFAULT_BBR"
        "--set-str DEFAULT_TCP_CONG bbr"
        "-m NET_SCH_FQ_CODEL"
        "-e NET_SCH_FQ"
        "-d DEFAULT_FQ_CODEL"
        "-e DEFAULT_FQ"
      ]
    else
      [ ];

  ccHarderConfig =
    if cachyConfig.ccHarder then
      [
        "-d CC_OPTIMIZE_FOR_PERFORMANCE"
        "-e CC_OPTIMIZE_FOR_PERFORMANCE_O3"
      ]
    else
      [ ];

  autoFDOConfig =
    if cachyConfig.autoFDO then
      [
        "-e AUTOFDO_CLANG"
      ]
    else
      [ ];

  propellerConfig =
    if cachyConfig.propeller then
      [
        "-e PROPELLER_CLANG"
      ]
    else
      [ ];

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

  # custom made
  hdrConfig = lib.optionals cachyConfig.withHDR [ "-e AMD_PRIVATE_COLOR" ];

  # https://github.com/CachyOS/linux-cachyos/issues/187
  disableDebug = lib.optionals cachyConfig.withoutDebug [
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
