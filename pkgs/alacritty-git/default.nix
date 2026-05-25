{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "alacritty_git";
  prev = prev.alacritty;

  versionNyxPath = "pkgs/alacritty-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "alacritty";
    repo = "alacritty";
  };
  ref = "master";

  postOverride = prevAttrs: {
    # versionCheckHook (inherited from upstream nixpkgs) checks that
    # `alacritty --version` outputs the Nix-side $version string.
    # However, Alacritty always prints the semver from its Cargo.toml
    # (e.g. "alacritty 0.18.0-dev"), which never matches our
    # "unstable-YYYYMMDD-rev" version format, so the check always fails.
    doInstallCheck = false;

    postInstall =
      builtins.replaceStrings
        [
          "extra/alacritty.man"
          "extra/alacritty-msg.man"
          "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml"
        ]
        [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
        prevAttrs.postInstall;
  };
}
