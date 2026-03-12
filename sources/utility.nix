{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  forServers = builtins.elem "server" features;
  
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
    package = pkgs.chromium.override {
      enableWideVine = true;
    };
    nativeMessagingHosts = [ pkgs.kdePackages.plasma-browser-integration ];
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,TouchpadOverscrollHistoryNavigation"
      "--ozone-platform-hint=auto"
      "--disable-pinch"
    ];
  };
}
