{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic.appmenu-gtk3-module;
in
{
  options = {
    chaotic.appmenu-gtk3-module.enable =
      lib.mkOption {
        default = false;
        description = ''
          Sets the proper environment variable to use appmenu-gtk3-module.
        '';
      };
  };
  config = {
    environment.profileRelativeSessionVariables = lib.mkIf cfg.enable {
      XDG_DATA_DIRS = [ "${pkgs.appmenu-gtk3-module}/share/gsettings-schemas/appmenu-gtk3-module-0.7.6" ];
    };
  };
