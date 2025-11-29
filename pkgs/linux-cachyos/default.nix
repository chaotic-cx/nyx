{
  final,
  ...
}@inputs:

let
  inherit (final.stdenv) isx86_64 isLinux;
  inherit (final.lib.trivial) importJSON;

  # CachyOS repeating stuff.
  mainVersions = importJSON ./versions.json;
  ltsVersions = importJSON ./versions-lts.json;
  rcVersions = importJSON ./versions-rc.json;
  hardenedVersions = importJSON ./versions-hardened.json;

  ltoKernelAttrs = {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-lto.x86_64-linux.nix;

    inherit (import ./lib/llvm-pkgs.nix inputs) callPackage;
    useLTO = "thin";

    packagesExtend = import ./lib/llvm-module-overlay.nix inputs;

    zfsOverride = {
      inherit (final)
        autoreconfHook269
        util-linux
        coreutils
        perl
        udevCheckHook
        zlib
        libuuid
        python3
        attr
        openssl
        libtirpc
        nfs-utils
        gawk
        gnugrep
        gnused
        systemd
        smartmontools
        sysstat
        pkg-config
        curl
        pam
        nix-update-script
        ;
    };

    description = "Linux EEVDF-BORE scheduler Kernel by CachyOS built with LLVM and Thin LTO";
  };

  # Evaluation hack
  brokenReplacement = final.hello.overrideAttrs (prevAttrs: {
    meta = prevAttrs.meta // {
      platform = [ ];
      broken = true;
    };
  });

  isUnsupported = !isx86_64 || !isLinux;

  mkCachyKernel =
    if isUnsupported then
      # Evaluation hack
      _attrs: {
        kernel = brokenReplacement;
        recurseForDerivations = false;
      }
    else
      {
        callPackage ? final.callPackage,
        ...
      }@attrs:
      callPackage ./packages-for.nix (
        {
          versions = mainVersions;
          inherit inputs;
          cachyOverride = newAttrs: mkCachyKernel (attrs // newAttrs);
        }
        // attrs
      );

  gccKernel = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-gcc.x86_64-linux.nix;
    # since all flavors use the same versions.json, we just need the updateScript in one of them
    withUpdateScript = "stable";
  };
in
{
  inherit
    mainVersions
    rcVersions
    hardenedVersions
    mkCachyKernel
    ;

  cachyos-gcc = gccKernel;

  cachyos-lts = mkCachyKernel {
    taste = "linux-cachyos-lts";
    configPath = ./config-nix/cachyos-lts.x86_64-linux.nix;

    versions = ltsVersions;
    withUpdateScript = "lts";

    # Prevent building kernel modules for LTS kernel
    packagesExtend =
      _kernel: _final: prev:
      prev // { recurseForDerivations = false; };
  };

  cachyos-rc = mkCachyKernel {
    taste = "linux-cachyos-rc";
    configPath = ./config-nix/cachyos-rc.x86_64-linux.nix;

    versions = rcVersions;
    withUpdateScript = "rc";

    # Prevent building kernel modules for rc kernel
    packagesExtend =
      _kernel: _final: prev:
      prev // { recurseForDerivations = false; };
  };
  cachyos-lto = mkCachyKernel ltoKernelAttrs;

  cachyos-lto-znver4 = mkCachyKernel (
    ltoKernelAttrs
    // {
      configPath = ./config-nix/cachyos-znver4.x86_64-linux.nix;
    }
  );

  cachyos-sched-ext = throw "\"sched-ext\" patches were merged with \"cachyos\" flavor.";

  cachyos-server = mkCachyKernel {
    taste = "linux-cachyos-server";
    configPath = ./config-nix/cachyos-server.x86_64-linux.nix;
    basicCachy = false;
    cpuSched = "eevdf";
    ticksHz = 300;
    tickRate = "idle";
    preempt = "server";
    hugePages = "madvise";
    withDAMON = true;
    withNTSync = false;
    withHDR = false;
    description = "Linux EEVDF scheduler Kernel by CachyOS targeted for Servers";
  };

  cachyos-hardened = mkCachyKernel {
    taste = "linux-cachyos-hardened";
    configPath = ./config-nix/cachyos-hardened.x86_64-linux.nix;
    cpuSched = "hardened";

    versions = hardenedVersions;
    withUpdateScript = "hardened";

    withNTSync = false;
    withHDR = false;
  };

  zfs = final.zfs_2_3.overrideAttrs (prevAttrs: {
    src = if isUnsupported then brokenReplacement else gccKernel.zfs_cachyos.src;
    patches = [ ];
    passthru = prevAttrs.passthru // {
      kernelModuleAttribute = "zfs_cachyos";
    };
    postPatch = builtins.replaceStrings [ "grep --quiet '^Linux-M" ] [ "# " ] prevAttrs.postPatch;
  });
}
