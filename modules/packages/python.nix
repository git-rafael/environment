pkgs: with pkgs;
let
  developmentPackages = import ./development.nix pkgs;
in [
  poetry
] ++ developmentPackages.lite
