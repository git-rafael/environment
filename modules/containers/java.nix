{ pkgs }:
let
  packages = import ../packages/java.nix pkgs;
in {
  name = "environment";
  tag = "java";

  contents = packages;
}
