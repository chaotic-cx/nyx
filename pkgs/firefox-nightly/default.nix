{
  lib,
  current ? importJSON ./manifest.json,
  importJSON ? lib.trivial.importJSON,
  buildMozillaMach,
  callPackage,
  fetchurl,
  nss_git,
  nyxUtils,
  stdenv,
  # Temporary fixes:
  rust-cbindgen,
  fetchFromGitHub,
  rustPlatform,
  apple-sdk_26,
}:

let
  firefoxRepo = "mozilla-firefox/firefox";
  firefoxSourceRepo = "https://github.com/${firefoxRepo}";

  rust-cbindgen_latest =
    if lib.versionOlder rust-cbindgen.version "0.29.4" then
      rust-cbindgen.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "0.29.4";

          src = fetchFromGitHub {
            owner = "mozilla";
            repo = "cbindgen";
            tag = "${finalAttrs.version}";
            hash = "sha256-leeHOwpzXuzg2cTjXehBnCsS+dvU4eIIFtWKeCee20U=";
          };

          cargoDeps = rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            inherit (prevAttrs.cargoDeps) name;
            hash = "sha256-f6YoDoiVoh0BVPYHFO1FsdI4OCsF+LY72QaD57StdIQ=";
          };
        }
      )
    else
      rust-cbindgen;

  binaryName = "firefox-nightly";

  updateScript = callPackage ./update.nix { };

  removedPatches = [
    "133-env-var-for-system-dir.patch"
    "136-no-buildconfig.patch"
    "139-wayland-drag-animation.patch"
    "140-bindgen-string-view.patch"
  ];

  addedPatches = [
    ./env_var_for_system_dir-ff-unstable.patch
    ./no-buildconfig-ffx-unstable.patch
    ./relax-apple-sdk.patch
  ];

  isRustCbindgen =
    pkg:
    (pkg.outPath or null) == (rust-cbindgen.outPath or null)
    || lib.elem (pkg.pname or "") [
      "rust-cbindgen"
      "cbindgen"
    ];

  replaceRustCbindgen = pkg: if isRustCbindgen pkg then rust-cbindgen_latest else pkg;

  mach = buildMozillaMach {
    pname = "firefox-nightly";
    inherit binaryName updateScript;
    version = "${current.version}-${current.buildId}-${builtins.substring 0 7 current.rev}";
    applicationName = "Firefox Nightly";
    requireSigning = false;
    branding = "browser/branding/nightly";

    src = fetchurl {
      inherit (current) hash;
      url = "https://codeload.github.com/${firefoxRepo}/tar.gz/${current.rev}";
      name = "firefox.tar.gz";
    };

    meta = {
      description = "Web browser built from Firefox Nightly source tree";
      homepage = "https://www.firefox.com/";
      maintainers = with lib.maintainers; [ pedrohlc ];
      platforms = lib.platforms.unix;
      broken = stdenv.buildPlatform.is32bit;
      maxSilent = 14400;
      license = lib.licenses.mpl20;
      mainProgram = binaryName;
      hydraPlatforms = [ "x86_64-linux" ];
    };
  };

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByBaseNames removedPatches (prevAttrs.patches or [ ]) ++ addedPatches;

    env = (prevAttrs.env or { }) // {
      MOZ_SOURCE_REPO = firefoxSourceRepo;
      MOZ_SOURCE_CHANGESET = current.rev;
      MOZ_INCLUDE_SOURCE_INFO = "1";
    };

    nativeBuildInputs = map replaceRustCbindgen (prevAttrs.nativeBuildInputs or [ ]);

    buildInputs =
      (prevAttrs.buildInputs or [ ]) ++ lib.optional stdenv.hostPlatform.isDarwin apple-sdk_26;

    passthru = (prevAttrs.passthru or { }) // {
      inherit updateScript;
      rust-cbindgen = rust-cbindgen_latest;
    };
  };

  newInputs = {
    nss_latest = nss_git;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
