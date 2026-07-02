# NixOS module: where binaries/configs come from, state dir, systemd unit.
# Takes the flake's `self` to default package options to our own outputs.
{ self }:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.iam-alive-bot;
in {
  options.services.iam-alive-bot = {
    enable = lib.mkEnableOption "iam-alive-bot Telegram activity monitor";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.iam-alive-bot;
      description = "Bot binary derivation. Override to run a dev build.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "${self.packages.${pkgs.system}.iam-alive-bot-config}/share/iam_alive_bot/static_config.yaml";
      description = "Static config. Override for host-patched or nix-generated config.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "dsudakov";  # TODO: dedicated service user
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment for the unit (e.g. SQLITE_DB_PATH).";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.iam-alive-bot = {
      description = "iam-alive-bot Telegram activity monitor";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = cfg.environment;

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} -c ${cfg.configFile}";
        User = cfg.user;
        Group = cfg.group;

        # /var/lib/iam-alive-bot, owned by User:Group. SQLite db + WAL
        # sidecars live here; 0700 keeps the shm/wal private.
        StateDirectory = "iam-alive-bot";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/iam-alive-bot";

        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
