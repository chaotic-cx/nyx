{ final, prev, gitOverride, nyxUtils, ... }:

gitOverride {
  nyxKey = "nut_git";
  prev = prev.nut;

  versionNyxPath = "pkgs/nut-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "networkupstools";
    repo = "nut";
  };
  ref = "master";

  postOverride = prevAttrs: {
    configureFlags = prevAttrs.configureFlags ++ [ "--with-dev" ];
    buildInputs = with final; [ libgpiod_1 ] ++ prevAttrs.buildInputs;
    postPatch = ''
      substituteInPlace ./m4/nut_check_python.m4 \
        --replace-fail 'nut_cv_PYTHON3_SITE_PACKAGES=' \
          "nut_cv_PYTHON3_SITE_PACKAGES=\"$out/lib/python3.12/site-packages\" #"
    '';
    postInstall = builtins.replaceStrings [ "rm -r $out/share/solaris-init" ] [ "" ] prevAttrs.postInstall;
    # autoreconfHook seems to be broken for this one
    nativeBuildInputs = with final; [ python312 perl ] ++ prevAttrs.nativeBuildInputs;
    preAutoreconf = ''
      ./autogen.sh
    '';
    # rebased patches
    patches =
      let
        hardcodePaths = with final; (substituteAll {
          src = ./hardcode-paths.patch;
          avahi = "${avahi}/lib";
          freeipmi = "${freeipmi}/lib";
          libusb = "${libusb1}/lib";
          neon = "${neon}/lib";
          libmodbus = "${libmodbus}/lib";
          netsnmp = "${net-snmp.lib}/lib";
          libgpiod = "${libgpiod_1}/lib";
        });
      in
      nyxUtils.removeByName "hardcode-paths.patch" prevAttrs.patches
      ++ [ hardcodePaths ];
  };
}
