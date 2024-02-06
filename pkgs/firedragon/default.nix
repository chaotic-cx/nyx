{ buildMozillaMach
, callPackage
, lib
, stdenv
}:
let
  firedragon-src = callPackage ./firedragon.nix { };
in
((buildMozillaMach rec {
  applicationName = "FireDragon";
  binaryName = "firedragon";
  pname = "firedragon";
  src = firedragon-src.floorp;
  inherit (firedragon-src) extraConfigureFlags extraPatches extraPostPatch extraPassthru packageVersion;

  # Must match the contents of `browser/config/version.txt` in the source tree
  version = "115.7.0";

  updateScript = callPackage ./update.nix { };

  meta = {
    badPlatforms = lib.platforms.darwin;
    description = "Floorp fork build using custom branding & settings";
    homepage = "https://github.com/dr460nf1r3/firedragon-browser";
    license = lib.licenses.mpl20;
    maintainers = with lib; [ maintainers.dr460nf1r3 ];
    broken = stdenv.buildPlatform.is32bit; # since Firefox 60, build on 32-bit platforms fails with "out of memory".
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
  MOZ_REQUIRE_SIGNING = "";
  MOZ_SERVICES_HEALTHREPORT = "";
  MOZ_TELEMETRY_REPORTING = "";
  RUSTC_OPT_LEVEL = "2";
}
