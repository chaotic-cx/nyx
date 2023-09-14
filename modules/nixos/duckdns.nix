{ config, lib, pkgs, ... }:
let
  inherit (config.meta) username;
  inherit (config.users.users.${username}) group;
  cfg = config.chaotic.duckdns;
  fullDomain = "${cfg.domain}.duckdns.org";
in
{
  options.chaotic.duckdns = {
    enable = lib.mkEnableOption "DuckDNS config";
    enableCerts = lib.mkEnableOption "generate HTTPS cert via ACME/Let's Encrypt";
    domain = lib.mkOption {
      # TODO: accept a list of strings
      type = lib.types.str;
      description = "Domain to be updated";
    };
    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Environment file from systemd, ensure it is set to 600 permissions.

        Must contain DUCKDNS_TOKEN entry.
      '';
      default = "/etc/duckdns-updater/envs";
    };
    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "*:0/5";
      example = "hourly";
      description = ''
        How often the DNS entry is updated.

        The format is described in {manpage}`systemd.time(7)`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.duckdns-updater = {
      description = "DuckDNS updater";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [ curl ];
      script = ''
        readonly curl_out="$(echo \
        url="https://www.duckdns.org/update?domains=${cfg.domain}&token=$DUCKDNS_TOKEN&ip=&ipv6" \
        | curl --silent --config -)"

        echo "DuckDNS response: $curl_out"
        if [ "$curl_out" == "OK" ]; then
          >&2 echo "Domain updated successfully: ${cfg.domain}"
        else
          >&2 echo "Error while updating domain: ${cfg.domain}"
          exit 1
        fi
      '';

      serviceConfig = {
        DynamicUser = true;
        CapabilityBoundingSet = "";
        EnvironmentFile = cfg.environmentFile;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        PrivateDevices = true;
        ProtectHome = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        SystemCallFilter = "@system-service";
        Type = "oneshot";
      };
    };

    systemd.timers.duckdns-updater = {
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };

    security.acme = lib.mkIf cfg.enableCerts {
      acceptTerms = true;
      certs.${fullDomain} = {
        inherit group;
        email = "thiagokokada@gmail.com";
        dnsProvider = "duckdns";
        credentialsFile = cfg.environmentFile;
      };
    };

    systemd.services."acme-${fullDomain}-generate-pfx" = lib.mkIf cfg.enableCerts {
      description = "ACME generate PFX files";
      after = [ "acme-${fullDomain}.service" ];
      wants = [ "acme-${fullDomain}.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        coreutils
        (lib.getBin openssl)
      ];
      script = ''
        readonly filename='bundle.pfx'
        cd /var/lib/acme/${lib.escapeShellArg fullDomain}
        openssl pkcs12 -export -out "$filename" -inkey key.pem -in cert.pem -passout pass:
        chmod 640 "$filename"
      '';
      serviceConfig = {
        User = "acme";
        Group = group;
        UMask = "0022";
        StateDirectoryMode = "750";
        ProtectSystem = "strict";
        PrivateTmp = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ ];
        ReadWritePaths = [ "/var/lib/acme" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
      };
    };
  };
}
