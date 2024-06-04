{ lib, pkgs, config, ... }:
# Originally from https://github.com/nix-community/nur-combined/blob/1b7e474178abfdeb6f89142d37fcc4854a16a5a1/repos/oluceps/modules/scx.nix
let
  cfg = config.chaotic.scx;
in
{
  options.chaotic.scx = {
    enable = lib.mkEnableOption ''scx service,
    a scheduler daemon with wide variety of
    scheduling algorithms, that can be used to
    improve system performance. Requires a kernel
    with the SCX patchset applied. Currently
    all cachyos kernels have this patchset applied'';
    package = lib.mkPackageOptionMD pkgs "scx" { };
    scheduler = lib.mkOption {
      type = lib.types.enum [
        "scx_central"
        "scx_flatcg"
        "scx_lavd"
        "scx_layered"
        "scx_nest"
        "scx_pair"
        "scx_qmap"
        "scx_rlfifo"
        "scx_rustland"
        "scx_rusty"
        "scx_simple"
        "scx_userland"
      ];
      default = "scx_rustland";
      example = "scx_rusty";
      description = ''
        Which of the SCX's schedulers to use.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
