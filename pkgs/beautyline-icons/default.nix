{
  lib,
  stdenvNoCC,

  fetchgit,
  callPackage,

  gnome-icon-theme,
  gtk3,
  hicolor-icon-theme,
  jdupes,
}:

let
  current = lib.trivial.importJSON ./version.json;

  srcMeta = {
    group = "garuda-linux";
    owner = "themes-and-settings/artwork";
    repo = "beautyline";
  };

  gitUrl = "https://gitlab.com/${srcMeta.group}/${srcMeta.owner}/${srcMeta.repo}.git";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "BeautyLine";
  inherit (current) version;

  src = fetchgit {
    url = gitUrl;
    inherit (current) rev;
    sha256 = current.hash;
  };

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
    mkdir -p $out/share/icons/${finalAttrs.pname}
    cp -r * $out/share/icons/${finalAttrs.pname}/
    rm $out/share/icons/${finalAttrs.pname}/README.md
    gtk-update-icon-cache $out/share/icons/${finalAttrs.pname}
    jdupes --link-soft --recurse $out/share
    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "beautyline-icons";
    versionPath = "pkgs/beautyline-icons/version.json";
    fetchLatestRev = callPackage ../../shared/gitlab-rev-fetcher.nix { } "master" srcMeta;
    inherit gitUrl;
  };

  meta = {
    description = "BeautyLine icon theme mixed with Sweet icons";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.dr460nf1r3 ];
    platforms = lib.platforms.linux;
  };
})
