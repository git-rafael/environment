{ pkgs, home-manager, ... } : 

let
  packages = pkgs;

in {
  name = "environment";
  tag = "automation";

  config = {
    Cmd = [ "${packages.bash}/bin/bash" ];
  };
}
