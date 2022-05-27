{ pkgs }:
let
  packages = import ../packages/python.nix pkgs;
in {
  name = "environment";
  tag = "python";

  contents = packages;
}
