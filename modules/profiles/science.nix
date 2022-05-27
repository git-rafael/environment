{ config, lib, pkgs, ... }:

let
  sciencePackages = import ../packages/science.nix pkgs;

in {
  home.packages = sciencePackages.withIpython;
}
