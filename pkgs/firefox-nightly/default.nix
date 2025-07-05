{
  lib,
  current ? importJSON ./version.json,
  importJSON ? lib.trivial.importJSON,
  buildMozillaMach,
  callPackage,
  fetchurl,
  nss_git,
  nyxUtils,
  stdenv,
}:

let
  mach = buildMozillaMach rec {
    pname = "firefox-nightly";
    binaryName = "firefox-nightly";
    inherit (current) version;
    applicationName = "Firefox Nightly";
    requireSigning = false;
    branding = "browser/branding/nightly";
    src = fetchurl {
      inherit (current) hash;
      url = "https://hg.mozilla.org/mozilla-central/archive/${current.rev}.zip";
    };

    meta = {
      description = "A web browser built from Firefox Nightly source tree";
      homepage = "http://www.mozilla.com/en-US/firefox/";
      maintainers = with lib.maintainers; [ pedrohlc ];
      platforms = lib.platforms.unix;
      badPlatforms = lib.platforms.darwin;
      broken = stdenv.buildPlatform.is32bit;
      maxSilent = 14400;
      license = lib.licenses.mpl20;
      mainProgram = binaryName;
    };

    updateScript = callPackage ./update.nix { };
  };

  postOverride = prevAttrs: {
    patches =
      nyxUtils.removeByBaseNames [
        "firefox-mac-missing-vector-header.patch"
        "env_var_for_system_dir-ff133.patch"
        "no-buildconfig-ffx136.patch"
        "build-fix-RELRHACK_LINKER-setting-when-linker-name-i.patch"
        "139-relax-apple-sdk.patch"
      ] prevAttrs.patches
      ++ [
        ./env_var_for_system_dir-ff-unstable.patch
        ./no-buildconfig-ffx-unstable.patch
      ];
  };

  newInputs = {
    nss_latest = nss_git;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
