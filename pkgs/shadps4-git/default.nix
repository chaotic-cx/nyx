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

  postOverride = prevAttrs: {
    cmakeFlags = (prevAttrs.cmakeFlags or [ ]) ++ [
      "-DSPDLOG_FMT_EXTERNAL=ON"
      "-DENABLE_SYSTEM_LIBRARIES=ON"
      # ponytail: protobuf 36.0.0 (bundled) needs abseil 20250512.1.
      # System abseil is 20260107.1 → ABI mismatch at link time.
      # Provide the matching source so FetchContent skips the network clone.
      "-DFETCHCONTENT_SOURCE_DIR_ABSL=${
        final.fetchFromGitHub {
          owner = "abseil";
          repo = "abseil-cpp";
          rev = "20250512.1";
          hash = "sha256-eB7OqTO9Vwts9nYQ/Mdq0Ds4T1KgmmpYdzU09VPWOhk=";
        }
      }"
    ];
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
