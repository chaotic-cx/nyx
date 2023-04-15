{ inputs }: { config, lib, pkgs, ... }:
let
  cfg = config.chaotic;
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
    environment.systemPackages = with pkgs; [ appmenu-gtk3-module ];

    # This ensures GTK applications can load appmenu-gtk-module
    environment.profileRelativeSessionVariables = {
      XDG_DATA_DIRS = [ "/share/gsettings-schemas/appmenu-gtk3-module-0.7.6" ];
    };
  };
}
