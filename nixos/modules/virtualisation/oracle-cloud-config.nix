{ config, lib, pkgs, ... }:
with lib;
let
  gce = pkgs.google-compute-engine;
in
{
  imports = [
    ../profiles/qemu-guest.nix
  ];


  fileSystems."/" = {
    fsType = "ext4";
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
  };

  boot.growPartition = true;
  boot.initrd.availableKernelModules = [ "virtio_pci" ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # Generate a GRUB menu.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Allow root logins only using SSH keys
  # and disable password authentication in general
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "prohibit-password";
  services.openssh.passwordAuthentication = mkDefault false;

  # Rely on GCP's firewall instead
  networking.firewall.enable = mkDefault false;

  networking.useDHCP = true;

  networking.timeServers = [ "169.254.169.254" ];
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM6cbBwBNHSKXPkX4egQ7G9f+Lg1WdvTe/baapK6YYao rhys@normandy" ];
}
