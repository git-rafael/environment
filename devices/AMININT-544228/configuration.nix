{ inputs, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../os.nix
    ../ui.nix
  ];

  networking.hostName = "AMININT-544228";

  # Device options
  device.username = "rafaeloliveira";
  device.userDescription = "Rafael Oliveira";

  device.hasFingerprint = true;

  # Cloudflare warp
  services.cloudflare-warp.enable = true;
  security.pki.certificateFiles = [
    ../../resources/certificates/flash_warp_certificate.crt
  ];
}
