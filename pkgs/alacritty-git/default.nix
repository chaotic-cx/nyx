{ final, prev, alacrittyVersion, ... }:

prev.alacritty.overrideAttrs (prevAttrs: rec {
  inherit (alacrittyVersion) version;
  src = final.fetchFromGitHub {
    inherit (alacrittyVersion) rev hash;
    owner = "alacritty";
    repo = "alacritty";
  };
  cargoDeps = pa.cargoDeps.overrideAttrs (_: {
    inherit src;
    outputHash = alacrittyVersion.cargoHash;
  });
  postInstall =
    builtins.replaceStrings
      [ "extra/alacritty.man" "extra/alacritty-msg.man" "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml" ]
      [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
      pa.postInstall;
  passthru = pa.passthru // { updateScript = final.callPackage ./update.nix { }; };
})
