{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.chaotic.duckdns;
  inherit (cfg.certs) group httpPort;
in
{
  options.chaotic.duckdns = {
    enable = lib.mkEnableOption "DuckDNS config";
    ipv6 = {
      enable = lib.mkEnableOption "enable IPv6";
      device = lib.mkOption {
        type = lib.types.str;
        description = "Device to get IPv6.";
        default = "eth0";
      };
    };
    certs = {
      enable = lib.mkEnableOption "generate HTTPS cert via ACME/Let's Encrypt";
      useHttpServer = lib.mkEnableOption "use Lego's built-in HTTP server instead a request to DuckDNS";
      group = lib.mkOption {
        type = lib.types.str;
        default = config.security.acme.defaults.group or "acme";
        description = "Group account under which the activation runs.";
      };
      httpPort = lib.mkOption {
        type = lib.types.port;
        description = "Port number.";
        default = 80;
      };
    };
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
      path = with pkgs; [
        curl
        iproute2
      ];
      script =
        lib.optionalString cfg.ipv6.enable ''
          readonly ipv6addr="$(ip addr show dev '${cfg.ipv6.device}' | \
          sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d' | \
          grep -v '^fd' | \
          grep -v '^fe80' | \
          head -1)"

          echo "Got IPv6: $ipv6addr"
        ''
        + ''
          readonly curl_out="$(printf \
          'url="https://www.duckdns.org/update?domains=%s&token=%s&ip=&ipv6=%s"' \
          '${cfg.domain}' "$DUCKDNS_TOKEN" "''${ipv6addr:-}" \
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
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ]
        ++ lib.optionals cfg.ipv6.enable [ "AF_NETLINK" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        Type = "oneshot";
      };
    };

    systemd.timers.duckdns-updater = {
      description = "DuckDNS updater timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        Persistent = true;
      };
    };

    security.acme = lib.mkIf cfg.certs.enable {
      acceptTerms = true;
      certs.${cfg.domain} = {
        inherit group;
        dnsProvider = lib.mkIf (!cfg.certs.useHttpServer) "duckdns";
        credentialsFile = lib.mkIf (!cfg.certs.useHttpServer) cfg.environmentFile;
        listenHTTP = lib.mkIf cfg.certs.useHttpServer ":${toString httpPort}"; # any other port needs to be proxied
        postRun = ''
          ${lib.getBin pkgs.openssl}/bin/openssl pkcs12 -export -out bundle.pfx -inkey key.pem -in cert.pem -passout pass:
          chown 'acme:${group}' bundle.pfx
          chmod 640 bundle.pfx
        '';
      };
    };

    systemd.services."acme-${cfg.domain}" = {
      after = lib.mkIf (cfg.certs.enable && cfg.certs.useHttpServer) [ "duckdns-updater.service" ];
    };

    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.certs.enable && cfg.certs.useHttpServer) [
      httpPort
    ];
  };
}
