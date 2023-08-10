{ lib, bytecode-viewer-git-src, jre, nyxUtils, makeWrapper, maven }:

maven.buildMavenPackage rec {
  pname = "bytecode-viewer";
  version = nyxUtils.gitToVersion bytecode-viewer-git-src;

  src = bytecode-viewer-git-src;

  mvnHash = "sha256-VHepIRJGTj6gPKtsDgOHXTtw2dklwi2mALTaWzto/S4=";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/lib/bytecode-viewer
    install -Dm644 target/Bytecode-Viewer-*.jar $out/lib/bytecode-viewer/bytecode-viewer.jar

    makeWrapper ${jre}/bin/java $out/bin/bytecode-viewer \
      --add-flags "-jar $out/lib/bytecode-viewer/bytecode-viewer.jar"
  '';

  meta = with lib; {
    description = "An advanced yet user friendly Java reverse engineering suite";
    homepage = "https://bytecodeviewer.com/";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
