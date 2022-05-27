pkgs: with pkgs;
let
  developmentPackages = import ./development.nix pkgs;
in [
  jdk
  maven
  gradle
] ++ developmentPackages.lite
