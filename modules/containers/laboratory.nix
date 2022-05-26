{ pkgs } : {
  name = "environment";
  tag = "laboratory";

  config = {
    Cmd = [ "ipython" ];
  };
}
