{
  gitOverride,
  nyxUtils,
  prev,
  ...
}:

gitOverride {
  nyxKey = "nss_git";
  prev = prev.nss_latest;
  manifestPath = "pkgs/nss-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "mozilla";
    repo = "nss";
  };
  ref = "master";

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByBaseName "85_security_load_3.85+.patch" (prevAttrs.patches or [ ]) ++ [
      # Fix build.sh with external NSPR by avoiding a lookup of a local nspr.pc
      # that is not generated when NSS is built with --with-nspr.
      ./fix-external-nspr-pkg-config.patch

      # Add NIX_NSS_LIBDIR fallback for loading libsoftokn3.so and related libs
      # when standard library paths are unavailable (e.g., in Nix isolated environments).
      ./nss-nix-path-PR.patch
    ];
  };
}
