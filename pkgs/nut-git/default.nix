{
  final,
  prev,
  gitOverride,
  nyxUtils,
  ...
}:

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
    postPatch = ''
      substituteInPlace ./m4/nut_check_python.m4 \
        --replace-fail 'nut_cv_PYTHON3_SITE_PACKAGES=' \
          "nut_cv_PYTHON3_SITE_PACKAGES=\"$out/lib/python3.12/site-packages\" #"
    '';
    configureFlags = prevAttrs.configureFlags ++ [
      "--with-systemdsystempresetdir=$(out)/lib/systemd/system-preset"
      # PyNUT is trying to touch PYTHONPATH (TODO: Find a real fix)
      "--without-pynut"
    ];
    # autoreconfHook seems to be broken for this one
    nativeBuildInputs =
      with final;
      [
        python3
        perl
      ]
      ++ prevAttrs.nativeBuildInputs;
    preAutoreconf = ''
      ./autogen.sh
    '';
    # rebased patches
    patches =
      let
        hardcodePaths =
          with final;
          (substituteAll {
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
      nyxUtils.removeByName "hardcode-paths.patch" prevAttrs.patches ++ [ hardcodePaths ];
  };
}
