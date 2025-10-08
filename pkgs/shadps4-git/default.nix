{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "shadps4_git";
  prev = prev.shadps4;

  newInputs = {
    xbyak = final.xbyak.overrideAttrs (_prevAttrs: {
      cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];
    });
    renderdoc = null;
  };

  versionNyxPath = "pkgs/shadps4-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "shadps4-emu";
    repo = "shadPS4";
    fetchSubmodules = true;
  };
}
