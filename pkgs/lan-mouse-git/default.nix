{ prev, gitOverride, ... }:

gitOverride (current: {
  nyxKey = "lan-mouse_git";
  prev = prev.lan-mouse;

  versionNyxPath = "pkgs/lan-mouse-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "feschber";
    repo = "lan-mouse";
  };

  postOverride = _prevAttrs: {
    patches = [ ./no-describe.patch ];

    postPatch = ''
      substituteInPlace ./build.rs \
        --replace-fail '{git_describe}' '${current.version}'
    '';
  };
})
