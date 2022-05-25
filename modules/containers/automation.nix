{ pkgs, ... } : 

let
  packages = pkgs;

in {
  name = "environment";
  tag = "automation";

  config = {
    Cmd = [ "env-shell" ];
  };
}
