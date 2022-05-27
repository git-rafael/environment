{ config, lib, pkgs, ... }:

let
  codePackages = import ../packages/code.nix pkgs;
  sciencePackages = import ../packages/science.nix pkgs;

in {
  home.packages = codePackages ++ sciencePackages.full;
}
