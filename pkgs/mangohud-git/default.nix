{ final, prev, gitOverride, nyxUtils, mangohud32, ... }:

gitOverride {
  newInputs = { inherit mangohud32; };
  nyxKey = "mangohud_git";
  versionNyxPath = "pkgs/mangohud-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.mangohud;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "flightlessmango";
      repo = "MangoHud";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };

  postOverrides = [
    (prevAttrs: {
      patches = [ ./preload-nix-workaround.patch ] ++
        (nyxUtils.removeByBaseName "preload-nix-workaround.patch"
          (nyxUtils.removeByURL "https://github.com/flightlessmango/MangoHud/commit/3f8f036ee8773ae1af23dd0848b6ab487b5ac7de.patch"
            prevAttrs.patches
          ));
      postPatch = (prevAttrs.postPatch or "") + ''
        substituteInPlace src/meson.build \
          --replace "run_command(['git', 'describe', '--tags', '--dirty=+']).stdout().strip()" \
            "'${prevAttrs.version}'"
      '';
    })
  ];
}
