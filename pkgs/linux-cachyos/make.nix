{ taste
, configPath
, versions
, callPackage
, fetchFromGitHub
, linuxPackagesFor
, nyxUtils
, cpuSched ? "cachyos"
, kernelPatches ? { }
}:

let
  cachyConfig = { inherit taste cpuSched versions; };

  # The three phases of the config
  # - First we apply the changes fromt their PKGBUILD using kconfig;
  # - Then we NIXify it (in the update-script);
  # - Last state is importing the NIXified version for building.
  linuxConfigOriginal = callPackage ./configfile-raw.nix {
    inherit cachyConfig;
  };
  linuxConfigTransformable = callPackage ./configfile-bake.nix {
    configfile = linuxConfigOriginal;
  };
  linuxConfigTransfomed = import configPath;

  kernel = callPackage ./kernel.nix {
    inherit cachyConfig;
    kernelPatches = [ ];
    configfile = linuxConfigOriginal;
    config = linuxConfigTransfomed;
    cachyConfigBake = linuxConfigTransformable;
  };

  # CachyOS repeating stuff.
  addZFS = _finalAttrs: prevAttrs:
    let
      zfs = prevAttrs.zfsUnstable.overrideAttrs (prevAttrs: {
        src =
          fetchFromGitHub {
            owner = "cachyos";
            repo = "zfs";
            inherit (versions.zfs) rev hash;
          };
        meta = prevAttrs.meta // { broken = false; };
        patches = [ ];
      });
    in
    {
      kernel_configfile = prevAttrs.kernel.configfile;
      inherit zfs;
      zfsStable = zfs;
      zfsUnstable = zfs;
    };

  basePackages = linuxPackagesFor kernel;
  packagesWithZFS = basePackages.extend addZFS;
  packagesWithoutUpdateScript = nyxUtils.dropAttrsUpdateScript packagesWithZFS;
in
packagesWithoutUpdateScript // {
  _description = "Kernel and modules for ${taste}";
  kernel = basePackages.kernel; # This one still has the updateScript
}
