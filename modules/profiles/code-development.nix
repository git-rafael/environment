{ config, lib, pkgs, ... }:

let
  codePackages = import ../packages/code.nix pkgs;

in {
  imports = [
    ./development.nix
  ];

  home.packages = codePackages;
}
