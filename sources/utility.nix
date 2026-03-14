{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  forServers = builtins.elem "server" features;
  onOS = builtins.elem "os" features;

  btproximityMacs = [
    "98:D7:42:71:93:C5"
    "40:35:E6:1E:19:DF"
  ];

  btproximityThreshold = -5;
  btproximityScript = pkgs.writeShellScriptBin "btproximity"
    (builtins.readFile ../resources/scripts/btproximity);
  
  plasmaDnSwitcher = pkgs.writeShellScriptBin "plasma-dn-switcher" (builtins.readFile ../resources/scripts/plasma-dn-switcher);

  claude-code = pkgs.symlinkJoin {
    name = "claude-code";
    paths = [ edgePkgs.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --set CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
    '';
  };
  
  gtoken = pkgs.writers.writePython3Bin "gtoken" {
    libraries = with pkgs.python3Packages; [
      google-auth
      google-auth-oauthlib
    ]; 
  } (builtins.readFile ../resources/scripts/gtoken);
  
in  {
  home.packages = with pkgs; [
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
    
    bat
    tiv
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
    claude-code
  ] ++ pkgs.lib.optionals withUI [
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
        "BT_THRESHOLD=${toString btproximityThreshold}"
        "PATH=${pkgs.lib.makeBinPath (with pkgs; [ bluez gnugrep coreutils systemd dbus ])}"
        (let macsStr = builtins.concatStringsSep " " btproximityMacs; in "\"BT_DEVICE_MACS=${macsStr}\"")
      ];
    };
  };
}
