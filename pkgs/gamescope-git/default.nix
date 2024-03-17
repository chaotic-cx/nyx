{ final, prev, gitOverride, isWSI ? false, ... }:

gitOverride {
  newInputs = with final; {
    openvr = openvr_git;
  };

  nyxKey = if isWSI then "gamescope-wsi_git" else "gamescope_git";
  prev = if isWSI then prev.gamescope-wsi else prev.gamescope;

  versionNyxPath = "pkgs/gamescope-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "ValveSoftware";
    repo = "gamescope";
    fetchSubmodules = true;
  };
  ref = "master";
  withUpdateScript = !isWSI;

  postOverride = prevAttrs: {
    buildInputs = with final; [ seatd xwayland libdecor ] ++ (with xorg; [ xcbutilwm xcbutilerrors ]) ++ prevAttrs.buildInputs;

    patches = with final; prevAttrs.patches ++ [
      (fetchpatch2 {
        url = "https://github.com/ValveSoftware/gamescope/commit/85432af61b779a02b636fdc29d98aba5e89fcff7.patch";
        hash = "sha256-XmrozomRB0adizdZPH9yK9SOA02XrABl6DWciyNNQn0=";
      })
    ];
  };
}
