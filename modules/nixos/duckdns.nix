{ config, lib, pkgs, ... }:
let
  inherit (config.meta) username;
  inherit (config.users.users.${username}) group;
  cfg = config.chaotic.duckdns;
in
{
  options.chaotic.duckdns = {
    enable = lib.mkEnableOption "DuckDNS config";
    enableCerts = lib.mkEnableOption "generate HTTPS cert via ACME/Let's Encrypt";
    domain = lib.mkOption {
      # TODO: accept a list of strings
      type = lib.types.str;
      description = "Full domain to be updated, including the TLD.";
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
        readonly curl_out="$(printf \
        'url="https://www.duckdns.org/update?domains=%s&token=%s&ip="' \
        '${cfg.domain}' "$DUCKDNS_TOKEN" \
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
        CapabilityBoundingSet = "";
        DynamicUser = true;
        EnvironmentFile = cfg.environmentFile;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];
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
      certs.${cfg.domain} = {
        inherit group;
        dnsProvider = "duckdns";
        credentialsFile = cfg.environmentFile;
        postRun = ''
          ${lib.getBin pkgs.openssl}/bin/openssl pkcs12 -export -out bundle.pfx -inkey key.pem -in cert.pem -passout pass:
          chown 'acme:${group}' bundle.pfx
          chmod 640 bundle.pfx
        '';
      };
    };
  };
}
