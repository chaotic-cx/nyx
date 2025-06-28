{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.bazaar;

  contentConfigFile = pkgs.writeText "bazaar-content.yml" cfg.contentConfig;
  blocklistFile = pkgs.writeText "bazaar-blocklist.txt" cfg.blocklist;
in
{
  options.services.bazaar = {
    enable = mkEnableOption "Bazaar service";

    package = mkOption {
      type = types.package;
      default = pkgs.bazaar;
      description = "The Bazaar package to use.";
    };

    contentConfig = mkOption {
      type = types.str;
      default = ''
        sections:
          - title: "Bazaar for nix default selection"
            subtitle: "You should change this with services.bazaar.contentConfig"
            description: "These are some of my favorite apps!"
            rows: 3
            banner-fit: cover
            appids:
              - net.lutris.Lutris
              - org.mozilla.firefox
              - com.modrinth.ModrinthApp
              - org.blender.Blender
              - org.desmume.DeSmuME
              - com.system76.Popsicle
              - com.valvesoftware.Steam
              - org.gimp.GIMP
              - org.gnome.Builder
              - org.gnome.Loupe
              - org.inkscape.Inkscape
              - org.kde.krita
      '';
      description = "The bazaar configuration file content.";
    };

    blocklist = mkOption {
      type = types.str;
      default = ''

      '';
      description = "The bazaar blocklist file content.";
    };

  };

  config = mkIf cfg.enable {
    systemd.user.services.bazaar = {
      description = "Bazaar background service";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/bazaar service --extra-content-config ${contentConfigFile} --extra-blocklist ${blocklistFile}";
      };
    };
  };
}
