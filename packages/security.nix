{ pkgs, edgePkgs, features }:

let
  packages = with pkgs; [
    metasploit
    wapiti
    nikto

    tor
    nyx

    bind
    iputils
    inetutils

    tcpdump
    nmap

    socat
    netcat
    websocat

    sshpass
    sshuttle

    gitleaks

    oathToolkit
  ];

in packages
