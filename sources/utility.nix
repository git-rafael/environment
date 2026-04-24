{ pkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  onOS = builtins.elem "os" features;

  btproximityMacs = [
    "98:D7:42:71:93:C5"
    "40:35:E6:1E:19:DF"
  ];

  btproximityThreshold = -5;
  btproximityConnectRetrySecs = 30;
  btproximityScript = pkgs.writeShellScriptBin "btproximity"
    (builtins.readFile ../resources/scripts/btproximity);

  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../resources/scripts/env-load);
  plasmaDnSwitcher = pkgs.writeShellScriptBin "plasma-dn-switcher" (builtins.readFile ../resources/scripts/plasma-dn-switcher);

  gtoken = pkgs.writers.writePython3Bin "gtoken" {
    libraries = with pkgs.python3Packages; [
      google-auth
      google-auth-oauthlib
    ]; 
  } (builtins.readFile ../resources/scripts/gtoken);

in  {
  home.packages = with pkgs; [
    env-load
    ncurses
    gnugrep
    gnused
    gtoken
    gnutar
    gnupg
    gzip
    gawk
    wget
    zip
    jq
    television
    fd
    ripgrep
    binutils
    
    bat
    tiv
    chafa
    libsixel
    perl
    htop
    ctop
    iotop
    iftop
    rsync
    ffmpeg
    rename
    openssh
    pciutils
    findutils
    coreutils
    cifs-utils
    
    nix-index
    nix-prefetch-git
    
    bitwarden-cli
    home-assistant-cli
  ] ++ pkgs.lib.optionals onOS [
    sbctl
    efibootmgr
  ] ++ pkgs.lib.optionals withUI [
    ghostty
    reco
    plasmaDnSwitcher
  ];

  programs.chromium = {
    enable = withUI;
    package = pkgs.google-chrome;
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,TouchpadOverscrollHistoryNavigation"
      "--ozone-platform-hint=auto"
      "--disable-pinch"
    ];
  };
  home.file = pkgs.lib.mkIf withUI {
    ".config/google-chrome/NativeMessagingHosts/org.kde.plasma.browser_integration.json".source =
      "${pkgs.kdePackages.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
  };

  systemd.user.services.btproximity = pkgs.lib.mkIf onOS {
    Unit.Description = "Bluetooth proximity screen lock";
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart = "${btproximityScript}/bin/btproximity";
      Restart = "always";
      RestartSec = "5s";
      Environment = [
        "BT_LOCK_THRESHOLD=${toString btproximityThreshold}"
        "BT_CONNECT_RETRY_SECS=${toString btproximityConnectRetrySecs}"
        "PATH=${pkgs.lib.makeBinPath (with pkgs; [ bluez gnugrep coreutils systemd dbus ])}"
        (let macsStr = builtins.concatStringsSep " " btproximityMacs; in "\"BT_DEVICE_MACS=${macsStr}\"")
      ];
    };
  };
}
