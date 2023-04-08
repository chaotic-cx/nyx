# Totally based on nrdxp modules
{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.programs.gamescope;
  cfgSteam = config.programs.steam;
in
{
  options.programs.gamescope = {
    enable = mkEnableOption (mdDoc "gamescope");

    package = mkOption {
      type = types.package;
      default = pkgs.gamescope;
      defaultText = literalExpression "pkgs.gamescope";
      description = mdDoc ''
        The GameScope package to use.
      '';
    };

    capSysNice = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc ''
        Add cap_sys_nice capability to the GameScope binary.
      '';
    };

    args = mkOption {
      type = types.listOf types.string;
      default = [ ];
      example = [ "--rt" "--prefer-vk-device 8086:9bc4" ];
      description = mdDoc ''
        Arguments passed to GameScope on startup.
      '';
    };

    env = mkOption {
      type = types.attrsOf types.string;
      default = { };
      example = literalExpression ''
        # for Prime render offload on Nvidia laptops.
        # Also requires `hardware.nvidia.prime.offload.enable`.
        {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        }
      '';
      description = mdDoc ''
        Default environment variables available to the GameScope process, overridable at runtime.
      '';
    };

    session = mkOption {
      description = mdDoc "Run a GameScope driven Steam session from your display-manager";
      type = types.submodule {
        options.enable = mkEnableOption (mdDoc "GameScope Session");
      };
    };
  };

  config = 
    let
      gamescope-wrapped = callPackage ../pkgs/gamescope-wrapped {
        gamescope = cfg.package;
        gamescopeArgs = cfg.args;
        gamescopeEnv = cfg.env;
      };

      gamescopeSessionStarter = pkgs.writeShellScriptBin "steam-gamescope" ''
        ${gamescope-wrapped}/bin/gamescope --steam \
          -- ${configSteam.package}/bin/steam -tenfoot -pipewire-dmabuf
      '';

      gamescopeSessionFile = (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
        [Desktop Entry]
        Name=Steam
        Comment=A digital distribution platform
        Exec=${gamescopeSessionStarter}/bin/steam-gamescope
        Type=Application
      '').overrideAttrs (_: { passthru.providedSessions = [ "steam" ]; });
    in
    {
      security.wrappers = lib.mkIf (cfg.enable && cfg.capSysNice) {
        gamescope = {
          owner = "root";
          group = "root";
          source = "${gamescope-wrapped}/bin/gamescope";
          capabilities = "cap_sys_nice+pie";
        };
        # needed or steam fails
        bwrap = lib.mkIf cfg.session.enable {
          owner = "root";
          group = "root";
          source = "${pkgs.bubblewrap}/bin/bwrap";
          setuid = true;
        };
      };

      environment.systemPackages =
        lib.optional (cfg.enable) [gamescope-wrapped]
        ++ lib.optional cfg.session.enable gamescopeSessionStarter;

      programs.gamescope.enable = lib.mkDefault cfg.session.enable;
      programs.steam.enable = lib.mkDefault cfg.session.enable;

      services.xserver.displayManager.sessionPackages = lib.mkIf cfg.session.enable [ gamescopeSessionFile ];
    };

  meta.maintainers = with maintainers; [ pedrohlc ];
}
