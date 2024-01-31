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
  ] ++ pkgs.lib.optionals toWork [
    pritunl-ssh
    pritunl-client
  ] ++ pkgs.lib.optionals withUI [
    spotify
    edgePkgs.logseq
  ] ++ pkgs.lib.optionals (withUI && toWork) [
    slack
  ] ++ pkgs.lib.optionals (withUI && toPlay) [
    discord
    edgePkgs.steam
  ] ++ pkgs.lib.optionals isServer [
    python311Packages.supervisor
  ];
}
