{
  lib,
  importJSON ? lib.trivial.importJSON,
  current ? importJSON ./manifest.json,
  buildMozillaMach,
  callPackage,
  fetchFromGitHub,
  nss_git,
  nyxUtils,
  stdenv,

  # Temporary fixes:
  rust-cbindgen,
  rustPlatform,
}:

let
  firefoxOwner = "mozilla-firefox";
  firefoxRepo = "firefox";
  firefoxSourceRepo = "https://github.com/${firefoxOwner}/${firefoxRepo}";
  binaryName = "firefox-nightly";
  version = "${current.version}-${current.buildId}-${builtins.substring 0 7 current.rev}";
  firefoxSrc = fetchFromGitHub {
    inherit (current) hash rev;
    owner = firefoxOwner;
    repo = firefoxRepo;
  };

  rust-cbindgen_latest =
    if lib.versionOlder rust-cbindgen.version "0.29.4" then
      rust-cbindgen.overrideAttrs (
        finalAttrs: prevAttrs: {
          version = "0.29.4";

          src = fetchFromGitHub {
            owner = "mozilla";
            repo = "cbindgen";
            tag = finalAttrs.version;
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

  updateScript = callPackage ./update.nix { };

  removedPatches = [
    "133-env-var-for-system-dir.patch"
    "136-no-buildconfig.patch"
  ];

  addedPatches = [
    ./env_var_for_system_dir-ff-unstable.patch
    ./no-buildconfig-ffx-unstable.patch
  ];

  mach =
    (buildMozillaMach {
      pname = "firefox-nightly";
      inherit
        binaryName
        updateScript
        version
        ;
      applicationName = "Firefox Nightly";
      branding = "browser/branding/nightly";
      src = firefoxSrc;
      extraPatches = addedPatches;

      extraPassthru = {
        rust-cbindgen = rust-cbindgen_latest;
      };

      meta = {
        description = "Web browser built from Firefox Nightly source tree";
        homepage = "https://www.firefox.com/";
        maintainers = with lib.maintainers; [
          pedrohlc
        ];
        platforms = lib.platforms.unix;
        broken = stdenv.buildPlatform.is32bit;
        maxSilent = 14400;
        license = lib.licenses.mpl20;
        mainProgram = binaryName;
        hydraPlatforms = [
          "x86_64-linux"
        ];
      };
    }).override
      {
        enableAddonSigning = false;
        nss_latest = nss_git;
        rust-cbindgen = rust-cbindgen_latest;
      };
in
mach.overrideAttrs (prevAttrs: {
  env = (prevAttrs.env or { }) // {
    MOZ_SOURCE_REPO = firefoxSourceRepo;
    MOZ_SOURCE_CHANGESET = current.rev;
    MOZ_INCLUDE_SOURCE_INFO = "1";
  };

  patches = nyxUtils.removeByBaseNames removedPatches (prevAttrs.patches or [ ]);
})
