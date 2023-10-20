{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;
  isServer = builtins.elem "server" features;

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
  ] ++ pkgs.lib.optionals isServer [
    python311Packages.supervisor
  ];

in packages
