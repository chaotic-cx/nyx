{ fetchFromGitLab
, fetchurl
, lib
, pkgs
, ...
}:
let
  current = lib.trivial.importJSON ./version.json;
  packageVersion = current.firedragonSource.version;

  settings = fetchFromGitLab {
    owner = "garuda-linux/firedragon";
    repo = "settings";
    fetchSubmodules = false;
    inherit (current.firedragonSettings) rev hash;
  };
in
rec {
  extraConfigureFlags = [
    "--disable-crashreporter"
    "--disable-debug"
    "--disable-debug-js-modules"
    "--disable-debug-symbols"
    "--disable-default-browser-agent"
    "--disable-gpsd"
    "--disable-necko-wifi"
    "--disable-parental-controls"
    "--disable-rust-tests"
    "--disable-tests"
    "--disable-updater"
    "--disable-warnings-as-errors"
    "--disable-webspeech"
    "--enable-bundled-fonts"
    "--enable-eme=widevine"
    "--enable-jxl"
    "--enable-proxy-bypass-protection"
    "--enable-raw"
    "--enable-sandbox"
    "--enable-strip"
    "--with-app-basename=FireDragon"
    "--with-app-name=firedragon"
    "--with-distribution-id=org.garudalinux"
    "--with-unsigned-addon-scopes=app,system"
  ];

  extraNativeBuildInputs = [ pkgs.zstd ];

  extraPrefsFiles = [ "${settings}/firedragon.cfg" ];

  extraPoliciesFiles = [ "${settings}/distribution/policies.json" ];

  extraPassthru = {
    firedragon = { inherit src; };
    inherit extraPrefsFiles extraPoliciesFiles;
  };

  inherit packageVersion;

  src = fetchurl {
    url = "https://gitlab.com/api/v4/projects/55893651/packages/generic/firedragon/${packageVersion}/firedragon-v${packageVersion}.source.tar.zst";
    inherit (current.firedragonSource) hash;
  };

  version = current.firefoxVersion;
}
