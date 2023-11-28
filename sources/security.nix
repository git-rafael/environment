{ pkgs, edgePkgs, features, ... }:

let
  metasploit = edgePkgs.metasploit;
in {
  home.packages = with pkgs; [
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
}
