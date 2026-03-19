{ inputs, config, pkgs, lib, ... }:

let
  epson-printer-utility = pkgs.stdenv.mkDerivation rec {
    pname = "epson-printer-utility";
    version = "1.2.2-1";

    src = pkgs.fetchurl {
      url = "https://download3.ebz.epson.net/dsc/f/03/00/16/74/30/9067c71049e81fbbee48a4695c5c0acf308b9f18/epson-printer-utility_1.2.2-1_amd64.deb";
      hash = "sha256-8OG2Hva+7FGA9s8x/7uH9IMbgRgez6zl5z1XA32RRJI=";
    };

    nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook makeWrapper ];

    buildInputs = with pkgs; [
      libusb1
      cups
      qt5.qtbase
    ];

    dontUnpack = true;
    dontWrapQtApps = true;

    installPhase = ''
      mkdir -p $out/extracted
      dpkg -x $src $out/extracted

      # Move app files from FHS paths
      cp -r $out/extracted/opt/epson-printer-utility/{lib,resource} $out/
      install -Dm755 $out/extracted/opt/epson-printer-utility/bin/epson-printer-utility $out/libexec/epson-printer-utility

      # Install ecbd daemon
      install -Dm755 $out/extracted/usr/lib/epson-backend/ecbd $out/lib/epson-backend/ecbd

      rm -rf $out/extracted

      # Create bin wrapper with Qt plugin path
      mkdir -p $out/bin
      makeWrapper $out/libexec/epson-printer-utility $out/bin/epson-printer-utility \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt5.qtbase.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}"

      # Desktop entry
      mkdir -p $out/share/applications
      cat > $out/share/applications/epson-printer-utility.desktop <<'DESKTOP'
[Desktop Entry]
Version=1.0
Name=Epson Printer Utility
Type=Application
Categories=Utility;Printing;
Exec=epson-printer-utility
Terminal=false
Icon=@out@/resource/Images/AppIcon.png
DESKTOP
      substituteInPlace $out/share/applications/epson-printer-utility.desktop \
        --replace-warn "@out@" "$out"
    '';
  };
in

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
    epson-printer-utility
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

  # Symlink required by hardcoded path in epson-printer-utility binary
  system.activationScripts.epson-printer-utility = ''
    mkdir -p /opt
    ln -sfn ${epson-printer-utility} /opt/epson-printer-utility
  '';

  # Epson Communication Backend Daemon (required by epson-printer-utility)
  systemd.services.ecbd = {
    description = "Epson Printer Utility Daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${epson-printer-utility}/lib/epson-backend/ecbd";
      Restart = "on-failure";
    };
  };
}
