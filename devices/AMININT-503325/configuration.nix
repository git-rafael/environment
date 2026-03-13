{ inputs, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../os.nix
    ../ui.nix
  ];

  networking.hostName = "AMININT-503325";

  # Options
  device.hasFingerprint = true;

  # ThinkPad keyboard layout variant
  services.xserver.xkb.variant = "thinkpad";

  # Cloudflare warp
  services.cloudflare-warp.enable = true;
  security.pki.certificateFiles = [
    ../../resources/certificates/flash_warp_certificate.crt
  ];

  # Users
  users.users.rafael = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Rafael Oliveira";
    extraGroups = [ "networkmanager" "lp" "scanner" "docker" "wheel" ];
  };
}
