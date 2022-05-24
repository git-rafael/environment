{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    google-chrome
    
    vscode
    #libsecret
    #gnome-keyring
    #libgnome-keyring
  ];

in {  
  home.packages = packages;
}
