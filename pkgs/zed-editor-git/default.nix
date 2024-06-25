{ final, prev, gitOverride, zedPins, ... }:

gitOverride {
  nyxKey = "zed-editor_git";
  prev = prev.zed-editor;

  versionNyxPath = "pkgs/zed-editor-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "zed-industries";
    repo = "zed";
  };
  ref = "main";

  withCargoDeps = lockFile: final.rustPlatform.importCargoLock {
    lockFileContents = builtins.readFile lockFile;
    outputHashes = zedPins;
  };

  postOverride = prevAttrs: {
    postPatch = (prevAttrs.postPatch or "") + ''
      sed -i"" 's+zed::node_binary_path()?+"${final.nodejs_18}"+g' extensions/*/src/*.rs
    '';
    env = prevAttrs.env // { OPENSSL_NO_VENDOR = 1; };
  };
}
