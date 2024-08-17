{ buildMozillaMach
, callPackage
, fetchurl
, lib
}:
let
  current = lib.trivial.importJSON ./version.json;
  firedragon-src = callPackage ./firedragon.nix { };
  packageVersion = current.version;
in
((buildMozillaMach rec {
  applicationName = "FireDragon";
  binaryName = "firedragon";
  pname = "firedragon";
  branding = "browser/branding/firedragon";
  requireSigning = false;
  allowAddonSideload = true;

  src = fetchurl {
    url = "https://gitlab.com/api/v4/projects/55893651/packages/generic/firedragon/${packageVersion}/firedragon-v${packageVersion}.source.tar.zst";
    inherit (current) hash;
  };

  inherit packageVersion;
  inherit (firedragon-src) extraConfigureFlags extraNativeBuildInputs;

  # Must match the contents of `browser/config/version.txt` in the source tree
  version = "128.1.0";

  updateScript = callPackage ./update.nix { };

  meta = {
    badPlatforms = lib.platforms.darwin;
    description = "Floorp fork build using custom branding & settings";
    homepage = "https://github.com/dr460nf1r3/firedragon-browser";
    license = lib.licenses.mpl20;
    maintainers = with lib; [ maintainers.dr460nf1r3 ];
    # broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
    maxSilent = 14400; # 4h, double the default of 7200s (c.f. #129212, #129115)
    platforms = lib.platforms.unix;
    mainProgram = "firedragon";
  };
}).override {
  crashreporterSupport = false;
  enableOfficialBranding = false;
  pgoSupport = true;
  privacySupport = true;
  webrtcSupport = true;
}).overrideAttrs {
  MOZ_APP_REMOTINGNAME = "firedragon";
  MOZ_CRASHREPORTER = "";
  MOZ_DATA_REPORTING = "";
  MOZ_TELEMETRY_REPORTING = "";
  OPT_LEVEL = "3";
  RUSTC_OPT_LEVEL = "3";
}
