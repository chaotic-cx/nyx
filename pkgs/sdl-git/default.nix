{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "sdl_git";
  prev = prev.SDL2;

  versionNyxPath = "pkgs/sdl-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "libsdl-org";
    repo = "SDL";
  };
  ref = "main";

  postOverride = prevAttrs: {
    patches = [ ];
    postPatch = ''
      substituteInPlace cmake/sdl3.pc.in \
        --replace 'libdir=''${prefix}/' 'libdir=' \
        --replace 'includedir=''${prefix}/' 'includedir=' \
        --replace 'exec_prefix=''${prefix}' '@CMAKE_INSTALL_BINDIR@'
    '';
    nativeBuildInputs = with final; [ cmake ] ++ prevAttrs.nativeBuildInputs;
  };
}
