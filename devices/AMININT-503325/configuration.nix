{ inputs, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../os.nix
    ../ui.nix
  ];

  networking.hostName = "AMININT-503325";

  # Device options
  device.username = "rafael";
  device.userDescription = "Rafael Oliveira";

  device.hasFingerprint = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;

  # ThinkPad keyboard layout variant
  services.xserver.xkb.variant = "thinkpad";

  # Cloudflare warp
  services.cloudflare-warp.enable = true;
  security.pki.certificateFiles = [
    ../../resources/certificates/flash_warp_certificate.crt
  ];
}
