{
  callPackage,
  mkProtonBinDerivation,
  lib,
  fetchzip,
  luxtorpedaVersion,
}:

mkProtonBinDerivation {
  pname = "luxtorpeda";
  inherit (luxtorpedaVersion) version;
  steamDisplayName = "Luxtorpeda";

  variants.x86_64-linux = {
    toolName = "Luxtorpeda";
    src = fetchzip {
      inherit (luxtorpedaVersion) url hash;
    };
  };

  passthru.updateScript = callPackage ./update.nix { };

  meta = with lib; {
    description = "Steam Play compatibility tool to run games using native Linux engines";
    homepage = "https://codeberg.org/luxtorpeda/luxtorpeda";
    changelog = "https://codeberg.org/luxtorpeda/luxtorpeda/releases/tag/v${luxtorpedaVersion.version}";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ pedrohlc ];
  };
}
