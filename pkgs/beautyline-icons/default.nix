{
  callPackage,
  fetchFromGitLab,
  gnome-icon-theme,
  gtk3,
  hicolor-icon-theme,
  jdupes,
  lib,
  stdenvNoCC,
  ...
}:

let
  current = lib.trivial.importJSON ./version.json;
  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/artwork";
    repo = "beautyline";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "BeautyLine";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  nativeBuildInputs = [
    jdupes
    gtk3
  ];

  propagatedBuildInputs = [
    gnome-icon-theme
    hicolor-icon-theme
  ];

  dontDropIconThemeCache = true;

  dontPatchELF = true;
  dontRewriteSymlinks = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/${pname}
    cp -r * $out/share/icons/${pname}/
    rm $out/share/icons/${pname}/README.md
    gtk-update-icon-cache $out/share/icons/${pname}
    jdupes --link-soft --recurse $out/share
    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit pname;
    nyxKey = "beautyline-icons";
    versionPath = "pkgs/beautyline-icons/version.json";
    fetchLatestRev = callPackage ../../shared/gitlab-rev-fetcher.nix { } "master" srcMeta;
    gitUrl = src.gitRepoUrl;
  };

  meta = with lib; {
    description = "BeautyLine icon theme mixed with Sweet icons";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline";
    license = licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.linux;
  };
}
