{
  final,
  prev,
  gitOverride,
  rustPlatform_latest,
  ...
}:

gitOverride {
  nyxKey = "servo_git";
  prev = prev.servo;

  newInputs = {
    rustPlatform = rustPlatform_latest;
  };

  versionNyxPath = "pkgs/servo-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "servo";
    repo = "servo";
  };

  postOverride = prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      (final.fetchpatch {
        url = "https://github.com/servo/servo/pull/37290.patch";
        hash = "sha256-hccPBm9vpUKHX7AFcDO3MGtKuagCczRE7oRVQxsl9R8=";
        revert = true;
      })
    ];
    meta = prevAttrs.meta // {
      broken = (prevAttrs.meta.broken or false) || final.stdenv.isDarwin;
    };
  };
}
