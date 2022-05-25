{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    google-chrome
    
    slack
    discord
    spotify

    vscode
    #libsecret
    #gnome-keyring
    #libgnome-keyring
  ];

in {  
  home.packages = packages;
}
