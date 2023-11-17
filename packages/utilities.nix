{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;
  toPlay = builtins.elem "play" features;
  toWork = builtins.elem "work" features;
  isServer = builtins.elem "server" features;

  ollama = pkgs.stdenvNoCC.mkDerivation rec {
    name = "ollama";
    version = "0.1.5";
    system = pkgs.system;

    passthru = rec {
      arch = {
        x86_64-linux = "amd64";
        aarch64-linux = "arm64";
      }.${system} or throwSystem;
      sha256 = {
        x86_64-linux = "sha256-ZBUL1ZQNx14Kzjqr0eeuBAw0OJ7D5V/FESfcmHiPrz0=";
        aarch64-linux = "sha256-GmcB9xDv4SL74ulSSLuzUzKe0W7LsK5SrLOcyo9HCzw=";
      }.${system} or throwSystem;
      throwSystem = throw "Unsupported ${system} for ${name}";
    };

    src = pkgs.fetchurl {
      sha256 = passthru.sha256;
      url = "https://github.com/jmorganca/ollama/releases/download/v${version}/ollama-linux-${passthru.arch}";
    };

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/ollama
      chmod +x $out/bin/ollama
    '';
  };

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

    ollama
    browsh
    firefox

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

    bitwarden-cli
    home-assistant-cli
  ] ++ pkgs.lib.optionals toWork [
    pritunl-ssh
    pritunl-client
  ] ++ pkgs.lib.optionals withUI [
    spotify
  ] ++ pkgs.lib.optionals (withUI && toWork) [
    slack
  ] ++ pkgs.lib.optionals (withUI && toPlay) [
    discord
    edgePkgs.steam
  ] ++ pkgs.lib.optionals isServer [
    python311Packages.supervisor
  ];

in packages
