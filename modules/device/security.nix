{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    metasploit

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

in {  
  home.packages = packages;
}
