{ pkgs }:
let
  packages = import ../packages/javascript.nix pkgs;
in {
  name = "environment";
  tag = "javascript";

  contents = packages;
}
