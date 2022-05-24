{ pkgs, ... } : 

let
  packages = pkgs;

in {
  name = "toolbox";
  tag = "automation";

  config = {
    Cmd = [ "${packages.hello}/bin/hello" ];
  };
}
