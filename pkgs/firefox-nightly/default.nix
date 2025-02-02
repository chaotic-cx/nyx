{ lib
, current ? importJSON ./version.json
, importJSON ? lib.trivial.importJSON
, buildMozillaMach
, callPackage
, fetchurl
, nss_git
, nyxUtils
, stdenv
, freetype
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
    # Freetype's derivation adds libpng to propagatedBuildInputs and the build system goes nuts
    # with two different versions of libpng. Sadly freetype itself is dependency of many packages.
    # So we need to hack the entire env.
    preConfigure = prevAttrs.preConfigure + ''
      export PKG_CONFIG_PATH="''${PKG_CONFIG_PATH//libpng-apng-${libpng.version}/corpse-0}"
      export NIX_CFLAGS_COMPILE="''${NIX_CFLAGS_COMPILE//libpng-apng-${libpng.version}/corpse-0}"
      export BINDGEN_EXTRA_CLANG_ARGS="''${BINDGEN_EXTRA_CLANG_ARGS//libpng-apng-${libpng.version}/corpse-0}"
      export PATH="''${PATH//libpng-apng-${libpng.version}/corpse-0}"
      export NIX_LDFLAGS="''${NIX_LDFLAGS//libpng-apng-${libpng.version}/corpse-0}"
      export HOST_PATH="''${HOST_PATH//libpng-apng-${libpng.version}/corpse-0}"
    '';
    passthru = prevAttrs.passthru // { libpng = libpng; libpng_pinned = libpng_pinned; };
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
    freetype = freetype.override { libpng = libpng_pinned; };
  };
in
nyxUtils.multiOverride mach newInputs postOverride
