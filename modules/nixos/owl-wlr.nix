{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chaotic.owl-wlr;
in
{
  options.chaotic.owl-wlr = {
    enable = lib.mkEnableOption ''
      Owl - tiling wayland compositor based on wlroots. 
      Enabling this option will add owl to your system.
    '';

    package = lib.mkPackageOption pkgs "owl-wlr_git" {
      nullable = true;
      extraDescription = ''
        This option can provide different version of Owl compositor.
      '';
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        kitty
        rofi
      ]; # because default.conf requires both pkgs.kitty and pkgs.rofi
      defaultText = lib.literalExpression ''
        with pkgs; [
          kitty 
          rofi
        ];
      '';
      example = lib.literalExpression ''
        with pkgs; [
          foot
          fuzzel
          gtklock
          mako
          grimblast
        ];
      '';
      description = ''
        Extra packages to be installed system wide.
        Both pkgs.kitty and pkgs.rofi is required by default config.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = [ cfg.package ];

        systemd.packages = [ cfg.package ];

        xdg.portal = {
          enable = lib.mkDefault true;
          configPackages = [ cfg.package ];
        };
      }
    ]
  );

  meta.maintainers = with lib.maintainers; [ s0me1newithhand7s ];
}
