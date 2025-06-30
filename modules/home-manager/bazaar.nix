{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.chaotic.bazaar;

  contentConfigFile = pkgs.writeText "bazaar-content.yml" cfg.contentConfig;
  blocklistFile = pkgs.writeText "bazaar-blocklist.txt" cfg.blocklist;
in
{
  options.chaotic.bazaar = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the user-wide bazaar daemon, required to run the graphical store.
      '';
    };

    contentConfig = mkOption {
      type = types.str;
      default = ''
        sections:
          - title: "Bazaar for nix default selection"
            subtitle: "You should change this with chaotic.bazaar.contentConfig in HomeManager"
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
      description = ''
        The bazaar configuration yaml file content. See https://github.com/kolunmi/bazaar
      '';
    };

    blocklist = mkOption {
      type = types.str;
      default = "";
      description = "The bazaar blocklist file content in plaintext";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.bazaar = {
      Unit = {
        Description = "Bazaar background service";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bazaar_git}/bin/bazaar service --extra-content-config ${contentConfigFile} --extra-blocklist ${blocklistFile}";
      };
    };
  };
}
