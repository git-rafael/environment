{ nixpkgs, ... } : 

let
  pkgs = import nixpkgs { system="x86_64-linux"; };

in {
  name = "environment";
  tag = "laboratory";

  config = {
    Cmd = [ "ipython" ];
  };
}
