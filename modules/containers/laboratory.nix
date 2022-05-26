{ pkgs } : 
let
  laboratoryPackages = import ../packages/laboratory.nix pkgs;
in {
  name = "environment";
  tag = "laboratory";

  contents = laboratoryPackages;

  config = {
    Cmd = [ "${pkgs.ipython}/bin/ipython" ];
  };
}
