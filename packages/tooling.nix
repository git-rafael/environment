{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;

  packages = with pkgs; [
    ncurses
    gnugrep
    gnused
    gnutar
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
    openssh
    pciutils
    findutils
    coreutils
    cifs-utils

    pritunl-ssh
    pritunl-client

    bitwarden-cli
    home-assistant-cli
  ] ++ pkgs.lib.optionals withUI [
    slack
    discord
    spotify
  ];

in packages
