pkgs: with pkgs;
let
  developmentPackages = import ./development.nix pkgs;
in [
  (yarn.override { nodejs = null; })
] ++ developmentPackages.lite
