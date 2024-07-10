{ lib, callPackage, fetchFromGitHub, jre, makeWrapper, maven }:

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

  mvnHash = "sha256-vaKNleHwl0fwEi94BRjXNKQGhLstUkE+kKMB5nig5Uo=";

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

  meta = with lib; {
    description = "An advanced yet user friendly Java reverse engineering suite";
    homepage = "https://bytecodeviewer.com/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
