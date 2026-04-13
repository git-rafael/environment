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

  # Secure Boot via Lanzaboote (replaces systemd-boot)
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # TPM2-based LUKS auto-unlock (requires systemd initrd; enrollment done
  # at runtime via systemd-cryptenroll, see hardware-configuration.nix).
  boot.initrd.systemd.enable = true;

  environment.systemPackages = [ pkgs.sbctl ];

  # Cloudflare warp
  services.cloudflare-warp.enable = true;
  security.pki.certificateFiles = [
    ../../resources/certificates/flash_warp_certificate.crt
  ];
}
