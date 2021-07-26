{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.virtualisation.googleComputeImage;
  defaultConfigFile = pkgs.writeText "configuration.nix" ''
    { ... }:
    {
      imports = [
        <nixpkgs/nixos/modules/virtualisation/oracle-cloud-image.nix>
      ];
    }
  '';
in
{

  imports = [ ./oracle-cloud-config.nix ];

  options = {
    virtualisation.googleComputeImage.diskSize = mkOption {
      type = with types; either (enum [ "auto" ]) int;
      default = "auto";
      example = 1536;
      description = ''
        Size of disk image. Unit is MB.
      '';
    };

    virtualisation.googleComputeImage.configFile = mkOption {
      type = with types; nullOr str;
      default = null;
      description = ''
        A path to a configuration file which will be placed at `/etc/nixos/configuration.nix`
        and be used when switching to a new configuration.
        If set to `null`, a default configuration is used, where the only import is
        `<nixpkgs/nixos/modules/virtualisation/oracle-cloud-image.nix>`.
      '';
    };
  };

  #### implementation
  config = {

    system.build.googleComputeImage = import ../../lib/make-disk-image.nix {
      name = "oracle-cloud-image";
      format = "qcow2-compressed";
      partitionTableType = "efi";
      configFile = if cfg.configFile == null then defaultConfigFile else cfg.configFile;
      inherit (cfg) diskSize;
      inherit config lib pkgs;
    };

  };

}
