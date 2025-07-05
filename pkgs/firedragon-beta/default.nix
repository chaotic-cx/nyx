{
  lib,
  nyxUtils,
  stdenv,
  callPackage,
  buildMozillaMach,
  runCommand,

  deno,
  gcc,
  libarchive,
  node-gyp,
  nodejs,
  python3,
  rsync,
}:
let
  firedragon-src = callPackage ./firedragon.nix { };

  denoCache =
    runCommand "firedragon-deno-cache-${firedragon-src.packageVersion}"
      {
        nativeBuildInputs = [
          deno
          libarchive
        ];

        # added if this package ever unbreaks on darwin
        __darwinAllowLocalNetworking = true;

        outputHash = "sha256-yIej6Qw5dPkHviRjlpz038ZYOEsnNq4xcM+3r/lU62c=";
        outputHashMode = "recursive";
      }
      ''
        bsdtar --strip-components 2 \
          -xvf ${firedragon-src.src} \
          firedragon-source-v${firedragon-src.packageVersion}/firedragon

        mkdir $out

        export DENO_DIR="$out"

        deno install --frozen
      '';

  mach =
    (
      (buildMozillaMach {
        applicationName = "FireDragon Beta";
        binaryName = "firedragon";
        pname = "firedragon-beta";
        branding = "browser/branding/firedragon";
        requireSigning = false;
        allowAddonSideload = true;

        version = "138.0.0"; # lie about the version so we get icu77 not icu73...

        inherit (firedragon-src)
          extraConfigureFlags
          extraMakeFlags
          extraNativeBuildInputs
          extraPassthru
          extraPostPatch
          packageVersion
          src
          ;

        updateScript = callPackage ./update.nix { };

        meta = {
          badPlatforms = lib.platforms.darwin;
          description = "Floorp fork build using custom branding & settings";
          homepage = "https://firedragon.garudalinux.org";
          license = lib.licenses.mpl20;
          maintainers = with lib; [ maintainers.dr460nf1r3 ];
          broken = stdenv.buildPlatform.is32bit;
          maxSilent = 14400;
          platforms = lib.platforms.unix;
          mainProgram = "firedragon";
        };
      }).override
      {
        enableDebugSymbols = false;
        # Set upstream: https://gitlab.com/garuda-linux/firedragon/firedragon12/-/blob/a1beaa8099461dea12f56952bc8d8675269ce81e/gecko/mozconfigs/edition/firedragon.mozconfig#L13
        enableOfficialBranding = true;
        ltoSupport = false;
        pgoSupport = true;
        privacySupport = true;
        # pulseaudioSupport = true; # FIXME: is this one buggy?
        webrtcSupport = true;
      }
    ).overrideAttrs
      {
        LIBGL_ALWAYS_SOFTWARE = "true";
        MOZ_APP_REMOTINGNAME = "firedragon";
        MOZ_CRASHREPORTER = "";
        MOZ_DATA_REPORTING = "";
        MOZ_INCLUDE_SOURCE_INFO = "1";
        MOZ_TELEMETRY_REPORTING = "";
        MOZ_PROFILER_STARTUP = "1";
        # FIXME: this one is set on the AUR, but debug symbols are disabled so this makes no sense
        # MOZ_ENABLE_FULL_SYMBOLS = "1";
        OPT_LEVEL = "3";
        RUSTC_OPT_LEVEL = "3";
      };

  postOverride = prev: {
    inherit (firedragon-src) version; # ...then put the real version after buildMozillaMach evaluated
    __intentionallyOverridingVersion = true;

    # replace upstream firefox-esr-128-unwrapped.patches with backports
    patches = [
      # backport of env_var_for_system_dir-ff111.patch to firedragon 12
      ./env_var_for_system_dir-fd12.patch
      # backport of no-buildconfig-ffx121.patch to firedragon 12
      ./no-buildconfig-fd12.patch
      # build-fix-RELRHACK_LINKER-setting-when-linker-name-i.patch is already applied
      # firefox-mac-missing-vector-header.patch is already applied
    ];

    nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [
      deno
      gcc
      node-gyp
      nodejs
      python3
      rsync
    ];

    preConfigure =
      ''
        export DENO_DIR="$(mktemp -d)"
        cp -vr ${denoCache}/* "$DENO_DIR"
        chmod -R +w "$DENO_DIR"

        pushd firedragon
          deno install --frozen --cached-only --allow-scripts
          deno task build --write-buildid2
          deno task build --release-build-before
        popd
      ''
      + prev.preConfigure;

    postBuild =
      prev.postBuild
      + ''
        pushd firedragon
          deno task build --release-build-after
        popd
      '';

    passthru = prev.passthru // {
      inherit denoCache;
    };
  };
in

nyxUtils.multiOverride mach { } postOverride
