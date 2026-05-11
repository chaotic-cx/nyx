{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "pwvucontrol_git";
  prev = prev.pwvucontrol;

  versionNyxPath = "pkgs/pwvucontrol-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "saivert";
    repo = "pwvucontrol";
  };

  postOverride = prevAttrs: {
    # Add blueprint-compiler to build inputs so Meson finds it at configuration time
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.blueprint-compiler ];

    mesonFlags = (prevAttrs.mesonFlags or [ ]) ++ [
      # We set wrap_mode to 'nodownload' to prevent Meson from trying to download
      "-Dwrap_mode=nodownload"
    ];

    # new wireplumber dependency
    buildInputs = map (
      x: if x.pname or null == "wireplumber" then final.wireplumber else x
    ) prevAttrs.buildInputs;
  };
}
