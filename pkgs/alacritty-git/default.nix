{ final, prev, alacrittyVersion, ... }:

prev.alacritty.overrideAttrs (prevAttrs: rec {
  inherit (alacrittyVersion) version;
  src = final.fetchFromGitHub {
    inherit (alacrittyVersion) rev hash;
    owner = "alacritty";
    repo = "alacritty";
  };
  cargoDeps = prevAttrs.cargoDeps.overrideAttrs (_cargoPrevAttrs: {
    inherit src;
    outputHash = alacrittyVersion.cargoHash;
  });
  postInstall =
    builtins.replaceStrings
      [ "extra/alacritty.man" "extra/alacritty-msg.man" "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml" ]
      [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
      prevAttrs.postInstall;
  passthru = prevAttrs.passthru // { updateScript = final.callPackage ./update.nix { }; };
})
