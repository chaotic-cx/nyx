{ lib, pkgs, config, ... }:
# Originally from https://github.com/nix-community/nur-combined/blob/1b7e474178abfdeb6f89142d37fcc4854a16a5a1/repos/oluceps/modules/scx.nix
with lib;
let
  cfg = config.chaotic.scx;
in
{
  options.chaotic.scx = {
    enable = mkEnableOption "scx service";
    package = mkPackageOptionMD pkgs "scx" { };
    scheduler = mkOption {
      type = types.str;
      default = "scx_rustland";
      example = "scx_rusty";
      description = ''
        Which of the SCX's schedulers to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.scx = {
      wantedBy = [ "multi-user.target" ];
      description = "scheduler daemon";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = "${lib.getExe' cfg.package cfg.scheduler}";
        Restart = "on-failure";
      };
    };
  };
}
