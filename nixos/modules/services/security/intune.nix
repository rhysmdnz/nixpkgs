{ config
, pkgs
, lib
, ...
}:
with lib; let
  cfg = config.services.intune;
in
{
  options.services.intune = {
    enable = mkEnableOption (lib.mdDoc "Microsoft Intune");
  };


  config = mkIf cfg.enable {
    users.users.microsoft-identity-broker = {
      group = "microsoft-identity-broker";
      isSystemUser = true;
    };

    users.groups.microsoft-identity-broker = { };
    environment.systemPackages = [ pkgs.microsoft-identity-broker pkgs.intune-portal ];
    systemd.packages = [ pkgs.microsoft-identity-broker ];

    systemd.services.microsoft-identity-device-broker.serviceConfig.ExecStartPre = "";
    systemd.user.services.microsoft-identity-broker.serviceConfig.ExecStartPre = "";

    systemd.tmpfiles.packages = [ pkgs.intune-portal ];
    services.dbus.packages = [ pkgs.microsoft-identity-broker ];
  };

  meta = {
    maintainers = with maintainers; [ rhysmdnz ];
  };
}
