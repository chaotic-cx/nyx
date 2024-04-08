{ final, ... }@inputs:

let
  inherit (final.lib.trivial) importJSON;

  # CachyOS repeating stuff.
  mainVersions = importJSON ./versions.json;

  mkCachyKernel = attrs: final.callPackage ./make.nix
    ({ inherit zfs-source; versions = mainVersions; } // attrs);

  stdenvLLVM = final.callPackage ./stdenv-llvm.nix { };

  zfs-source = final.fetchFromGitHub {
    owner = "cachyos";
    repo = "zfs";
    inherit (mainVersions.zfs) rev hash;
  };

  llvmModule = import ./llvm-module-overlay.nix inputs stdenvLLVM;
in
{
  inherit mainVersions mkCachyKernel;

  cachyos = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos.x86_64-linux.nix;
    # since all flavors use the same versions.json, we just need the updateScript in one of them
    withUpdateScript = true;
  };

  cachyos-lto = mkCachyKernel {
    taste = "linux-cachyos";
    configPath = ./config-nix/cachyos-lto.x86_64-linux.nix;

    stdenv = stdenvLLVM;
    useLTO = "thin";

    description = "Linux EEVDF-BORE scheduler Kernel by CachyOS built with LLVM and Thin LTO";

    packagesExtend = kernel: _finalModules: builtins.mapAttrs (k: v:
      if builtins.elem k [ "zenpower" "v4l2loopback" "zfs_cachyos" "virtualbox" ]
      then llvmModule kernel v
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

    withNTSync = false;
    withHDR = false;

    versions = mainVersions // {
      linux = {
        version = "6.7.12";
        hash = "sha256:113rf3jqfpf3wcv637zbq5ww2hpaaf23y6dsmkds01l8jkipjabc";
      };
    };
  };

  zfs = final.zfs_unstable.overrideAttrs (prevAttrs: {
    src = zfs-source;
    patches = [ ];
    passthru = prevAttrs.passthru // {
      kernelModuleAttribute = "zfs_cachyos";
    };
  });
}
