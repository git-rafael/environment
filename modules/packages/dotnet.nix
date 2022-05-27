pkgs: with pkgs;
let
  developmentPackages = import ./development.nix pkgs;
in [
  dotnet-sdk
  dotnet-aspnetcore
] ++ developmentPackages.lite
