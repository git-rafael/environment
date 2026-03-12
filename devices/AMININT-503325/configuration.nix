{ inputs, config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../os.nix
    ../ui.nix
  ];

  networking.hostName = "AMININT-503325";

  # ThinkPad keyboard layout variant
  services.xserver.xkb.variant = "thinkpad";

  # Fingerprint reader
  services.fprintd.enable = true;
  security.pam.services.sddm = {
    fprintAuth = true;
    rules.auth.fprintd.args = [ "try_first_identified" ];
  };

  # Cloudflare warp
  services.cloudflare-warp.enable = true;

  # Users
  users.users.rafael = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Rafael Oliveira";
    extraGroups = [ "networkmanager" "lp" "scanner" "docker" "wheel" ];
    packages = with pkgs; [
      kdePackages.yakuake
      kdePackages.kdepim-addons
    ];
  };
}
