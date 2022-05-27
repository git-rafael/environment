{ config, lib, pkgs, ... }:

let
  developmentPackages = import ../packages/development.nix pkgs;

in {
  home.packages = developmentPackages.full;
}
