{
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "pcsx2_git";
  prev = prev.pcsx2;

  versionNyxPath = "pkgs/pcsx2-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "PCSX2";
    repo = "pcsx2";
  };
  ref = "master";

  postOverride =
    old:
    let
      gitTag =
        if old.src ? rev then "git-${prev.lib.substring 0 7 old.src.rev}" else "git-${old.version}";
    in
    {
      postPatch = ''
        substituteInPlace cmake/Pcsx2Utils.cmake \
          --replace-fail 'set(PCSX2_GIT_TAG "")' 'set(PCSX2_GIT_TAG "${gitTag}")'
      '';

      buildInputs = old.buildInputs or [ ] ++ [ prev.rapidyaml ];
    };
}
