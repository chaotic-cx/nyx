{
  lib,
  importJSON ? lib.trivial.importJSON,
  current ? importJSON ./manifest.json,
  buildMozillaMach,
  callPackage,
  fetchNpmDeps,
  fetchurl,
  nodejs,
  npmHooks,
  nss_git,
  nyxUtils,
  python314,
  stdenv,

  # Platform-specific:
  apple-sdk_26,

  # Temporary fixes:
  fetchFromGitHub,
  rust-cbindgen,
  rustPlatform,
}:

let
  firefoxRepo = "mozilla-firefox/firefox";
  firefoxSourceRepo = "https://github.com/${firefoxRepo}";
  binaryName = "firefox-nightly";
  version = "${current.version}-${current.buildId}-${builtins.substring 0 7 current.rev}";
  firefoxSrc = fetchurl {
    inherit (current) hash;
    url = "https://codeload.github.com/${firefoxRepo}/tar.gz/${current.rev}";
    name = "firefox.tar.gz";
  };

  newtabNpmDeps = fetchNpmDeps {
    src = firefoxSrc;
    sourceRoot = "firefox-${current.rev}/browser/extensions/newtab";
    hash = current.newtabNpmDepsHash;
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

  updateScriptPackage = callPackage ./update.nix { };
  updateScript = lib.getExe updateScriptPackage;

  removedPatches = [
    "133-env-var-for-system-dir.patch"
    "136-no-buildconfig.patch"
    "139-wayland-drag-animation.patch"
    "140-bindgen-string-view.patch"
    "153-cbindgen-0.29.4-compat.patch"
  ];

  addedPatches = [
    ./env_var_for_system_dir-ff-unstable.patch
    ./no-buildconfig-ffx-unstable.patch
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
    inherit
      binaryName
      updateScript
      version
      ;
    applicationName = "Firefox Nightly";
    requireSigning = false;
    branding = "browser/branding/nightly";
    src = firefoxSrc;
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
  };

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByBaseNames removedPatches (prevAttrs.patches or [ ]) ++ addedPatches;

    env = (prevAttrs.env or { }) // {
      MOZ_SOURCE_REPO = firefoxSourceRepo;
      MOZ_SOURCE_CHANGESET = current.rev;
      MOZ_INCLUDE_SOURCE_INFO = "1";
    };

    nativeBuildInputs = map replaceRustCbindgen (prevAttrs.nativeBuildInputs or [ ]) ++ [
      nodejs
    ];

    buildInputs =
      (prevAttrs.buildInputs or [ ]) ++ lib.optional stdenv.hostPlatform.isDarwin apple-sdk_26;

    preBuild = (prevAttrs.preBuild or "") + ''
      (
        readonly newtab_root="''${MOZ_OBJDIR%/*}/browser/extensions/newtab"

        export npmDeps=${newtabNpmDeps}
        export npmRoot="$newtab_root"

        source ${npmHooks.npmConfigHook}/nix-support/setup-hook
        npmConfigHook

        ${lib.getExe python314} -c ${lib.escapeShellArg ''
          import hashlib
          import sys
          from pathlib import Path

          newtab_root = Path(sys.argv[1])
          lockfile = newtab_root / "package-lock.json"
          stamp = newtab_root / "node_modules" / ".newtab-install-stamp"

          with lockfile.open("rb") as lockfile_stream:
              digest = hashlib.file_digest(lockfile_stream, "sha256").digest()

          stamp.write_bytes(digest)
        ''} "$newtab_root"

        test -f "$newtab_root/node_modules/webpack/bin/webpack.js"
      )
    '';

    passthru = (prevAttrs.passthru or { }) // {
      inherit
        newtabNpmDeps
        updateScript
        updateScriptPackage
        ;
      rust-cbindgen = rust-cbindgen_latest;
    };
  };

  newInputs = {
    nss_latest = nss_git;
  };
in
nyxUtils.multiOverride mach newInputs postOverride
