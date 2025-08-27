{
  final,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "openmohaa_git";
  prev = final.openmohaa;

  versionNyxPath = "pkgs/openmohaa-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "openmoh";
    repo = "openmohaa";
  };

  postOverride = prevAttrs: {
    buildInputs =
      prevAttrs.buildInputs
      ++ (with final; [
        freetype
        libmad
        opusfile
      ]);
    cmakeFlags = prevAttrs.cmakeFlags ++ [ "-DUSE_INTERNAL_JPEG=1" ];
  };
}
