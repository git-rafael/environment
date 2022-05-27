{ config, lib, pkgs, ... }:

let
  sciencePackages = import ../packages/science.nix pkgs;

in {
  # home.packages = sciencePackages.withIpython;

  home.packages = pkgs.buildFHSUserEnv {
    name = "pipzone";
    targetPkgs = pkgs: sciencePackages.withIpython;
    runScript = "bash";
  };
}
