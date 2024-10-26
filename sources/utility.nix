{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  toPlay = builtins.elem "play" features;
  toWork = builtins.elem "work" features;
  isServer = builtins.elem "server" features;
  
in  {
  home.packages = with pkgs; [
    ncurses
    gnugrep
    gnused
    gnutar
    gnupg
    gzip
    gawk
    wget
    zip
    jq

    bat
    tiv
    yai
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
  ];
}
