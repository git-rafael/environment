{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;

  forWork = builtins.elem "work" features;
  forServers = builtins.elem "server" features;
  
  gtoken = pkgs.writers.writePython3Bin "gtoken" {
    libraries = with pkgs.python3Packages; [
      google-auth
      google-auth-oauthlib
    ]; 
  } (builtins.readFile ../resources/scripts/gtoken);
  
  chrome = pkgs.google-chrome.override {
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,TouchpadOverscrollHistoryNavigation"
      "--ozone-platform-hint=auto"
      "--disable-pinch"
    ];
  };
  
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
    xclip
    rename
    openssh
    pciutils
    findutils
    coreutils
    cifs-utils

    bitwarden-cli
    home-assistant-cli
    
    edgePkgs.ollama
  ] ++ pkgs.lib.optionals withUI [
    chrome
  ];
}
