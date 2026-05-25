{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride (current: {
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

  postOverride = _prevAttrs: {
    # Generate COMMIT and SOURCE_DATE_EPOCH in prePatch (before nixpkgs's
    # postPatch uses $(cat COMMIT)). nixpkgs uses postFetch with leaveDotGit
    # because it pins a fixed immutable tag (v.0.13.0). We pin a git rev
    # which can become unstable if upstream cleans up, because git metadata
    # participates in the hash when leaveDotGit is set.
    prePatch = ''
      printf "${builtins.substring 0 8 current.rev}" > COMMIT
      echo "1970-01-01T00:00:00Z" > SOURCE_DATE_EPOCH
    '';
  };
})
