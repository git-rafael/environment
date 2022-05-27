{ config, lib, pkgs, ... }:

let
  codePackages = import ../packages/code.nix pkgs;
  developmentPackages = import ../packages/development.nix pkgs;

in {
  home.packages = codePackages ++ developmentPackages.lite;
}
