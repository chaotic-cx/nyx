{ final, ... }@inputs:

let
  inherit (final.lib.trivial) importJSON;

  # CachyOS repeating stuff.
  mainVersions = importJSON ./versions.json;
  rcVersions = importJSON ./versions-rc.json;
  hardenedVersions = importJSON ./versions-hardened.json;

  mkCachyKernel = attrs: final.callPackage ./packages-for.nix ({ versions = mainVersions; } // attrs);

  stdenvLLVM = final.callPackage ./lib/llvm-stdenv.nix { };

  mainKernel = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos.x86_64-linux.nix;
    # since all flavors use the same versions.json, we just need the updateScript in one of them
    withUpdateScript = "stable";
  };

  llvmModuleOverlay = import ./lib/llvm-module-overlay.nix inputs stdenvLLVM;
in
{
  inherit mainVersions rcVersions hardenedVersions mkCachyKernel;

  cachyos = mainKernel;

  cachyos-rc = mkCachyKernel {
    taste = "linux-cachyos-rc";
    configPath = ./config-nix/cachyos-rc.x86_64-linux.nix;

    versions = rcVersions;
    withUpdateScript = "rc";

    # Prevent building kernel modules for rc kernel
    packagesExtend = _kernel: _final: prev: prev // { recurseForDerivations = false; };
  };

  cachyos-lto = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-lto.x86_64-linux.nix;

    stdenv = stdenvLLVM;
    useLTO = "thin";

    description = "Linux EEVDF-BORE scheduler Kernel by CachyOS built with LLVM and Thin LTO";

    packagesExtend = kernel: _finalModules: builtins.mapAttrs (k: v:
      if builtins.elem k [ "zenpower" "v4l2loopback" "zfs_cachyos" "virtualbox" "xone" ]
      then llvmModuleOverlay kernel v
      else v
    );
  };

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
    inherit (mainKernel.zfs_cachyos) src;
    patches = [ ];
    passthru = prevAttrs.passthru // {
      kernelModuleAttribute = "zfs_cachyos";
    };
  });
}
