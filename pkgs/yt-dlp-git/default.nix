{ final
, flakes
, nyxUtils
, prev
, ...
}:

let
  date = flakes.yt-dlp-git-src.lastModifiedDate;
  year =
    builtins.substring 0 4 date;
  month =
    builtins.substring 4 2 date;
  day =
    builtins.substring 6 2 date;
  datedVersion = "${year}.${month}.${day}";
in
(final.python311Packages.toPythonApplication prev.python311Packages.yt-dlp).overrideAttrs (pa: rec {
  version = nyxUtils.gitToVersion flakes.yt-dlp-git-src;
  name = "${pa.pname}-${version}";
  src = flakes.yt-dlp-git-src;
  postPatch = (pa.postPatch or "") + ''
          echo "
    __version__ = '${datedVersion}'

    RELEASE_GIT_HEAD = '${flakes.yt-dlp-git-src.rev}'

    VARIANT = None

    UPDATE_HINT = None

    CHANNEL = 'chaotic-nyx'
          " > yt_dlp/version.py
  '';
}
)
