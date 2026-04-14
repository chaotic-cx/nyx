{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nss_git";
  prev = prev.nss_latest;

  versionNyxPath = "pkgs/nss-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "nss-dev";
    repo = "nss";
  };
  ref = "master";

  postOverride = prevAttrs: {
    patches =
      (builtins.filter (p: !prev.lib.hasSuffix "85_security_load_3.85+.patch" (toString p)) (
        prevAttrs.patches or [ ]
      ))
      # Add NIX_NSS_LIBDIR fallback for loading libsoftokn3.so and related libs
      # when standard library paths are unavailable (e.g., in Nix isolated environments).
      ++ [ ./nss-nix-path-PR.patch ];
  };
}
