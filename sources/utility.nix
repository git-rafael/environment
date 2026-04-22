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
  btproximityConnectRetrySecs = 30;
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

  agent-browser = pkgs.stdenv.mkDerivation {
    pname = "agent-browser";
    version = "0.20.13";
    src = pkgs.fetchurl {
      url = "https://github.com/vercel-labs/agent-browser/releases/download/v0.20.13/agent-browser-linux-x64";
      hash = "sha256-NcS6RcK0X8faGfPxDTMNMo53Vc/HyHO2IBoIOtbQrZk=";
    };
    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/agent-browser
      chmod +x $out/bin/agent-browser
    '' + pkgs.lib.optionalString withUI ''
      wrapProgram $out/bin/agent-browser \
        --set AGENT_BROWSER_EXECUTABLE_PATH "${pkgs.google-chrome}/bin/google-chrome-stable"
    '';
  };
  
  gtoken = pkgs.writers.writePython3Bin "gtoken" {
    libraries = with pkgs.python3Packages; [
      google-auth
      google-auth-oauthlib
    ]; 
  } (builtins.readFile ../resources/scripts/gtoken);

  herdrAsset = {
    x86_64-linux = {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-x86_64";
      sha256 = "04hayacgnj3wkkq4sxlbs9fi2xcg8lbi1xk8afavrp3fjbv66bd3";
    };
    aarch64-linux = {
      url = "https://github.com/ogulcancelik/herdr/releases/download/v0.5.0/herdr-linux-aarch64";
      sha256 = "17ab1hgfa9vfd4wxhgm4g9lq1yf0wv8giwbl9rqp715c3kbnln4j";
    };
  }.${pkgs.stdenv.hostPlatform.system} or null;

  herdr = if herdrAsset != null then pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.5.0";
    src = pkgs.fetchurl herdrAsset;
    dontUnpack = true;
    installPhase = ''
      install -Dm755 "$src" "$out/bin/herdr"
    '';
    meta = with pkgs.lib; {
      description = "Terminal workspace manager for AI coding agents";
      homepage = "https://herdr.dev";
      license = licenses.agpl3Plus;
      mainProgram = "herdr";
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  } else null;
  
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

    ollama
    claude-code
    agent-browser
    edgePkgs.codex
  ] ++ pkgs.lib.optionals (herdrAsset != null) [
    herdr
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
