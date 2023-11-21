{ lib
, current ? importJSON ./version.json
, importJSON ? lib.trivial.importJSON
, buildMozillaMach
, callPackage
, fetchurl
, nss_git
, nyxUtils
, stdenv
}:

let
  mach = buildMozillaMach
    rec {
      pname = "firefox-nightly";
      inherit (current) version;
      applicationName = "Mozilla Firefox Nightly";
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
        mainProgram = "firefox";
      };

      updateScript = callPackage ./update.nix { };
    };

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByBaseName "no-buildconfig-ffx96.patch" prevAttrs.patches;
    env.MOZ_REQUIRE_SIGNING = "";
  };
in
nyxUtils.multiOverride mach { nss_latest = nss_git; } postOverride
