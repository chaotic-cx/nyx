{ final
, gitOverride
, prev
, ...
}:

let
  current = final.lib.trivial.importJSON ./version.json;
  date = current.lastModifiedDate;
  year =
    builtins.substring 0 4 date;
  month =
    builtins.substring 4 2 date;
  day =
    builtins.substring 6 2 date;
  datedVersion = "${year}.${month}.${day}";
in
gitOverride
{
  nyxKey = "yt-dlp_git";
  versionNyxPath = "pkgs/yt-dlp-git/version.json";
  prev = final.python311Packages.toPythonApplication prev.python311Packages.yt-dlp;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitHub ({
      owner = "yt-dlp";
      repo = "yt-dlp";
    } // finalArgs);
  fetchLatestRev = src: final.callPackage ../../shared/github-rev-fetcher.nix { inherit src; ref = "master"; };
  inherit current;
  postOverrides = [
    (prevAttrs: {
      name = "${prevAttrs.pname}-${current.version}";
      postPatch = (prevAttrs.postPatch or "") + ''
              echo "
        __version__ = '${datedVersion}'

        RELEASE_GIT_HEAD = '${current.rev}'

        VARIANT = None

        UPDATE_HINT = None

        CHANNEL = 'chaotic-nyx'
              " > yt_dlp/version.py
      '';
    })
  ];
}
