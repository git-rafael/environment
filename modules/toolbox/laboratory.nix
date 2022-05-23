{ pkgs, ... } : 

let
  packages = pkgs;

in {
  name = "toolbox";
  tag = "laboratory";

  config = {
    Cmd = [ "${packages.hello}/bin/hello" ];
  };
}
