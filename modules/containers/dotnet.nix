{ pkgs }:
let
  packages = import ../packages/dotnet.nix pkgs;
in {
  name = "environment";
  tag = "dotnet";

  contents = packages;
}
