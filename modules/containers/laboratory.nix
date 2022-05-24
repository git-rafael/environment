{ pkgs, ... } : 

let
  packages = pkgs;

in {
  name = "environment";
  tag = "laboratory";

  config = {
    Cmd = [ "${packages.hello}/bin/hello" ];
  };
}
