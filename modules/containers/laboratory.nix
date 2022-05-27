{ pkgs } : 
let
  sciencePackages = import ../packages/science.nix pkgs;
in {
  name = "environment";
  tag = "laboratory";

  contents = sciencePackages.withIpython;

  config = {
    Cmd = [ "ipython" ];
  };
}
