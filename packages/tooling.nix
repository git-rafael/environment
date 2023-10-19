{ pkgs, edgePkgs, features }:

let
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

    bitwarden-cli
    home-assistant-cli
  ];

in packages
