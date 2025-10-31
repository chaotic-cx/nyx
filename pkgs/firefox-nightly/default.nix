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
  rust-cbindgen-updated = callPackage ./rust-cbindgen.nix { };

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
        "136-no-buildconfig.patch"
        "133-env-var-for-system-dir.patch"
        "142-relax-apple-sdk.patch"
      ] prevAttrs.patches
      ++ [
        ./env_var_for_system_dir-ff-unstable.patch
        ./no-buildconfig-ffx-unstable.patch
      ];
    nativeBuildInputs = builtins.map (
      pkg: if pkg.pname or "" == "rust-cbindgen" then rust-cbindgen-updated else pkg
    ) prevAttrs.nativeBuildInputs;
  };

  newInputs = {
    nss_latest = nss_git;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
