{ lib
, current ? importJSON ./version.json
, importJSON ? lib.trivial.importJSON
, buildMozillaMach
, callPackage
, fetchurl
, nss_git
, nyxUtils
, stdenv
, icu76
, libpng
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
    patches = nyxUtils.removeByBaseNames
      [ "env_var_for_system_dir-ff133.patch" "no-buildconfig-ffx121.patch" ]
      prevAttrs.patches ++ [ ./env_var_for_system_dir-ff-unstable.patch ./no-buildconfig-ffx-unstable.patch ];
    env = (prevAttrs.env or { }) // {
      MOZ_REQUIRE_SIGNING = "";
    };
    # Fix missing icu_76::UnicodeSet symbols
    postPatch = prevAttrs.postPatch + ''
      sed -i 's/icu-i18n/icu-uc &/' js/moz.configure
    '';
    # Fix libpng conflicts
    preConfigure = prevAttrs.preConfigure + ''
      export PKG_CONFIG_PATH="''${PKG_CONFIG_PATH/libpng-apng-1.6.43/buggy-corpse-1}"
    '';
  };

  libpng_pinned = libpng.overrideAttrs (_prevAttrs: rec {
    version = "1.6.46";
    src = fetchurl {
      url = "mirror://sourceforge/libpng/libpng-${version}.tar.xz";
      hash = "sha256-86qLcAOZirkqTpkGwY0ZhT6Zn507ypvRZo9U+oFwfLE=";
    };
    postPatch =
      "gunzip < ${fetchurl {
        url = "mirror://sourceforge/libpng-apng/libpng-${version}-apng.patch.gz";
      hash = "sha256-Kb7C39BG71HVLz5TIPkfr/yWvge0HZy51D2d9Veg0wM=";
      }} | patch -Np1";
  });

  newInputs = {
    nss_latest = nss_git;
    icu74 = icu76;
    libpng = libpng_pinned;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
