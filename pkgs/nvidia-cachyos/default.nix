{
  final,
  nyxUtils,
  variant ? "stable",
  linuxPackages_cachyos ? final.linuxPackages_cachyos,
  ...
}:

let
  inherit (final.lib.trivial) importJSON;
  inherit (nyxUtils) overrideFull;

  suffix = if variant == "stable" then "" else "-${variant}";
  versions = importJSON (./. + "/version${suffix}.json");

  updater = final.callPackage ./update.nix { inherit variant; };

  # Select the appropriate CachyOS Linux packages based on the variant
  cachyosLinuxPackages =
    if variant == "stable" then linuxPackages_cachyos else final."linuxPackages_cachyos-${variant}";

  # Mirrors the logic in pkgs/linux-cachyos/lib/llvm-module-overlay.nix
  fixNoVideo =
    prevDrv:
    prevDrv.overrideAttrs (prevAttrs: {
      passthru = prevAttrs.passthru // {
        settings = overrideFull (final // final.xorg) prevAttrs.passthru.settings;
        updateScript = updater;
      };
    });
in

if cachyosLinuxPackages ? nvidiaPackages then
  fixNoVideo (
    cachyosLinuxPackages.nvidiaPackages.mkDriver {
      inherit (versions) version;
      sha256_64bit = versions.hash;
      sha256_aarch64 = versions.aarch64Hash;
      openSha256 = versions.openHash;
      settingsSha256 = versions.settingsHash;
      persistencedSha256 = versions.persistencedHash;

      # Add any CachyOS specific patches if needed in the future
      patches = [ ];
    }
  )
else
  final.runCommand "unsupported-nvidia-cachyos" { } ''
    mkdir -p $out
    echo "nvidia-cachyos is unsupported on ${final.system}" > $out/README
  ''
