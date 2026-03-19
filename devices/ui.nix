{ inputs, config, pkgs, lib, ... }:
{
  # Enable the X11 windowing system (for XWayland apps)
  services.xserver.enable = true;
  services.xserver.xkb.layout = "br";

  # Enable Plasma Desktop Environment
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = let
    theme-conf = pkgs.writeText "sddm-breeze-theme" ''
      [General]
      type=color
      color=#000000
    '';
    breeze-black = pkgs.runCommand "sddm-breeze-black" {} ''
      mkdir -p $out/share/sddm/themes/breeze
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/. $out/share/sddm/themes/breeze/
      cp ${theme-conf} $out/share/sddm/themes/breeze/theme.conf.user
    '';
  in {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
    settings.Theme.ThemeDir = "${breeze-black}/share/sddm/themes";
  };

  security.pam.services = {
    sddm.kwallet.enable = true;
    login.fprintAuth = lib.mkIf config.device.hasFingerprint false;
  };

  programs.kde-pim = {
    enable = true;
    kmail = true;
    kontact = true;
    merkuro = true;
  };
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    qt6.qtwebengine
    kdePackages.yakuake
    kdePackages.kdepim-addons
    gutenprint
  ];

  # Enable print service with CUPS
  services.printing = {
    enable = true;
    drivers = [
      pkgs.epson-escpr
    ];
  };

  # Enable scan services with SANE
  hardware.sane = {
    enable = true;
    extraBackends = [
      pkgs.sane-airscan
    ];
  };
  services.udev.packages = [
    pkgs.sane-airscan
  ];
}
