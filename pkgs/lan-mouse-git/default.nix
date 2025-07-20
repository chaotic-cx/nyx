{
  prev,
  gitOverride,
  ...
}:

gitOverride (current: {
  nyxKey = "lan-mouse_git";
  prev = prev.lan-mouse;

  versionNyxPath = "pkgs/lan-mouse-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "feschber";
    repo = "lan-mouse";
  };
  withLastModified = true;

  postOverride = prevAttrs: {
    preConfigure = ''
      export OUT_DIR="$out"
    ''
    + (prevAttrs.preConfigure or "");

    prePatch = "";

    env = prevAttrs.env // {
      # sadly, "shadow-rs" doesn't help when we don't have a ".git", and ".git" is not
      # completely deterministic: https://github.com/NixOS/nixpkgs/issues/8567
      # Setting SOURCE_DATE_EPOCH is the best I can do here.
      SOURCE_DATE_EPOCH = current.lastModified;
    };
  };
})
