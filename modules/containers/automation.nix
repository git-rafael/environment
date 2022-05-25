{ pkgs, ... } : 

let
  packages = pkgs;

in {
  fromImage = "nixos/nix";
  name = "environment";
  tag = "automation";

  config = {
    Cmd = [ "env-shell" ];
  };
}
