{ final
, gitOverride
, prev
, ...
}:

let
  override = x: final.python312Packages.toPythonApplication (gitOverride x);
in
override (current:
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
  prev = prev.python312Packages.yt-dlp;
  newInputs = {
    requests = final.python312Packages.requests.overrideAttrs (prevAttrs: rec {
      version = "2.32.2";
      src = final.python312Packages.fetchPypi {
        inherit (prevAttrs) pname;
        inherit version;
        hash = "sha256-3ZUf9ezz47OqJrQHA7p3SV2rQdqDmucu88jl2OJDMok=";
      };
    });
  };

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
    format = "pyproject";

    nativeBuildInputs = with final.python312Packages; [
      hatchling
    ] ++ prevAttrs.nativeBuildInputs;
    postPatch = (prevAttrs.postPatch or "") + ''
            echo "
      __version__ = '${datedVersion}'

      RELEASE_GIT_HEAD = '${current.rev}'

      VARIANT = None

      UPDATE_HINT = None

      CHANNEL = 'master'

      ORIGIN = 'chaotic-cx/nyx'

      _pkg_version = '${datedVersion}'
            " > yt_dlp/version.py
    '';
  };
})
