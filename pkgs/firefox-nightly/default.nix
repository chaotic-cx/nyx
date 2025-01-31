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
    env = (prevAttrs.env or {}) // {
      MOZ_REQUIRE_SIGNING = "";
    };
    # Fix a dep conflict
    preConfigure = prevAttrs.preConfigure + ''
      export PKG_CONFIG_PATH="${libpng_pinned.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
    '';
  };

  libpng_pinned = libpng.overrideAttrs (_prevAttrs: {
    version = "1.6.45";
    src = fetchurl {
        url = "mirror://sourceforge/libpng/libpng-1.6.45.tar.xz";
        hash = "sha256-kmSFNQE5/7Ue9pdg2zX3iEbIBf7z1Zv9yy+6cEZj83A=";
    };
    postPatch =
      "gunzip < ${fetchurl {
      url = "mirror://sourceforge/libpng-apng/libpng-1.6.45-apng.patch.gz";
      hash = "sha256-aulUljivHlsmkH4BVnHQCldh7qk+Mm9Xbf6CsIVnJ0w=";
      }} | patch -Np1";
  });

  newInputs = {
    nss_latest = nss_git;
    icu74 = icu76;
    libpng = libpng_pinned;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
