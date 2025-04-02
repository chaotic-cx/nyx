{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.chaotic.appmenu-gtk3-module;
in
{
  options = with lib; {
    chaotic.appmenu-gtk3-module.enable = mkOption {
      default = false;
      example = true;
      type = types.bool;
      description = ''
        Sets the proper environment variable to use appmenu-gtk3-module.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ appmenu-gtk3-module ];
      sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.appmenu-gtk3-module}/share/gsettings-schemas/appmenu-gtk3-module-0.7.6"
      ];
      variables.UBUNTU_MENUPROXY = "1";
    };
  };
}
