{ final, prev, gitOverride, ... }:

gitOverride (current: {
  nyxKey = "lan-mouse_git";
  prev = prev.lan-mouse;

  versionNyxPath = "pkgs/lan-mouse-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "feschber";
    repo = "lan-mouse";
  };

  postOverride = prevAttrs: {
    buildInputs = with final; prevAttrs.buildInputs
      ++ lib.optional stdenv.hostPlatform.isDarwin darwin.apple_sdk.frameworks.ApplicationServices;

    env = prevAttrs.env // {
      GIT_DESCRIBE = "${current.version}-chaotic-nyx";
    };
  };
})
