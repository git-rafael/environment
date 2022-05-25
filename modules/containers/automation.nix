{ pkgs, ... } : 

let
  packages = pkgs;

in {
  name = "environment";
  tag = "automation";

  contents = home-manager.lib.homeManagerConfiguration rec {
      system = system;
      username = "system";
      homeDirectory = "/home/${username}";
      configuration.imports = [
        ../profiles/base.nix
        ../profiles/shell.nix
        ../profiles/systems.nix
        ../profiles/security.nix
      ];
    };

  config = {
    Cmd = [ "${packages.bash}/bin/bash" ];
  };
}
