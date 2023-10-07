{ final
, gitOverride
, prev
, ...
}:

gitOverride (current:
let
  date = current.lastModifiedDate;
  year =
    builtins.substring 0 4 date;
  month =
    builtins.substring 4 2 date;
  day =
    builtins.substring 6 2 date;
  datedVersion = "${year}.${month}.${day}";
in
{
  nyxKey = "yt-dlp_git";
  prev = final.python311Packages.toPythonApplication prev.python311Packages.yt-dlp;

  versionNyxPath = "pkgs/yt-dlp-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "yt-dlp";
    repo = "yt-dlp";
  };
  ref = "master";
  withLastModifiedDate = true;

  postOverride = prevAttrs: {
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
  };
})
