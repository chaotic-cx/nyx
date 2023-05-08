# Totally based on nrdxp modules
_:
{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.chaotic.gamescope;
  cfgSteam = config.programs.steam;
  cfgSession = cfg.session;
in
{
  options = rec {
    chaotic.gamescope = {
      enable = mkEnableOption (mdDoc "gamescope");

      package = mkOption {
        type = types.package;
        default = pkgs.gamescope;
        defaultText = literalExpression "pkgs.gamescope";
        description = mdDoc ''
          The GameScope package to use.
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

      session = {
        enable = mkEnableOption (mdDoc "GameScope Session");

        args = mkOption {
          type = types.listOf types.string;
          default = config.chaotic.gamescope.args;
          inherit (chaotic.gamescope.args) example;
          description = mdDoc ''
            Arguments to be passed to GameScope for the session.
          '';
        };

        env = mkOption {
          type = types.attrsOf types.string;
          default = config.chaotic.gamescope.env;
          inherit (chaotic.gamescope.env) example;
          description = mdDoc ''
            Environmental variables to be passed to GameScope for the session.
          '';
        };

        steamArgs = mkOption {
          type = types.listOf types.string;
          default = [ "-tenfoot" "-pipewire-dmabuf" ];
          example = [ "-tenfoot" "-pipewire-dmabuf" ];
          description = mdDoc ''
            Arguments to be passed to Steam inside the GameScope session.
          '';
        };
      };
    };
  };

  config =
    let
      gamescope-wrapped = pkgs.callPackage ../pkgs/gamescope-wrapped {
        gamescope = cfg.package;
        gamescopeArgs = cfg.args;
        gamescopeEnv = cfg.env;
      };

      gamescopeSessionStarter = pkgs.callPackage ../pkgs/gamescope-wrapped {
        gamescope = cfg.package;
        gamescopeArgs = cfgSession.args ++ [ "--steam" "--" "${cfgSteam.package}/bin/steam" ] ++ cfgSession.steamArgs;
        gamescopeEnv = cfgSession.env;
        gamescopeExecutable = "steam-gamescope";
        gamescopeVulkanLayers = false;
      };

      gamescopeSessionFile = (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
        [Desktop Entry]
        Name=Steam
        Comment=A digital distribution platform
        Exec=${gamescopeSessionStarter}/bin/steam-gamescope
        Type=Application
      '').overrideAttrs (_: { passthru.providedSessions = [ "steam" ]; });
    in
    {
      environment.systemPackages =
        lib.optional cfg.enable gamescope-wrapped
        ++ lib.optional cfgSession.enable gamescopeSessionStarter;

      # Forces gamescope & steam for gamescope.session
      chaotic.gamescope.enable = lib.mkIf cfgSession.enable true;
      programs.steam.enable = lib.mkIf cfgSession.enable true;

      services.xserver.displayManager.sessionPackages = lib.mkIf cfgSession.enable [ gamescopeSessionFile ];
    };

  meta.maintainers = with maintainers; [ pedrohlc ];
}
