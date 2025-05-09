{
  pkgs,
  agsBundle,
}:
let
  current = pkgs.lib.trivial.importJSON ./version.json;
  src = pkgs.fetchFromGitHub {
    inherit (current) rev hash;
    owner = "FilipTLW";
    repo = "vo1ded-panel";
  };
in
agsBundle {
  inherit src;
  name = "vo1ded-panel";
  extraPackages = with pkgs; [
    astal_tray
    astal_hyprland
  ];
}
