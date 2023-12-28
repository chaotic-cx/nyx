{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "input-leap_git";
  prev = prev.input-leap;

  versionNyxPath = "pkgs/input-leap-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "input-leap";
    repo = "input-leap";
  };
  ref = "master";

  postOverride = prevAttrs: {
    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with final; [
      gtest
      ghc_filesystem
    ]);
    buildInputs = prevAttrs.buildInputs ++ (with final; [
      libuuid
    ]);
    cmakeFlags = [
      "-DINPUTLEAP_USE_EXTERNAL_GTEST=ON"
    ];
    postFixup = builtins.replaceStrings
      [ "input-leap.desktop" ]
      [ "io.github.input_leap.InputLeap.desktop" ]
      prevAttrs.postFixup;
  };
}
