{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    fortune
  ];

in {  
  home.packages = packages;
}
