{
  lib,
  fetchFromGitHub,
  callPackage,

  maven,
  jre,
  makeWrapper,
}:

let
  current = lib.trivial.importJSON ./version.json;
in
maven.buildMavenPackage rec {
  pname = "bytecode-viewer";
  inherit (current) version;

  src = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "Konloch";
    repo = "bytecode-viewer";
  };

  mvnHash = "sha256-lp5kOspQWstT+b2Xg0RsTCIJ6wjbw5b+Yn/wZWIfDhc=";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/lib/bytecode-viewer
    install -Dm644 target/Bytecode-Viewer-*.jar $out/lib/bytecode-viewer/bytecode-viewer.jar

    makeWrapper ${jre}/bin/java $out/bin/bytecode-viewer \
      --add-flags "-jar $out/lib/bytecode-viewer/bytecode-viewer.jar"
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit pname;
    nyxKey = "bytecode-viewer_git";
    versionPath = "pkgs/bytecode-viewer-git/version.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" src;
    gitUrl = src.gitRepoUrl;
  };

  meta = {
    description = "An advanced yet user friendly Java reverse engineering suite";
    homepage = "https://bytecodeviewer.com/";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ pedrohlc ];
  };
}
