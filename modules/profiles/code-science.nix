{ config, lib, pkgs, ... }:

let
  codePackages = import ../packages/code.nix pkgs;
  sciencePackages = import ../packages/science.nix pkgs;

in {
  imports = [
    ./science.nix
  ];

  home.packages = codePackages ++ sciencePackages.withJupyter;
}
