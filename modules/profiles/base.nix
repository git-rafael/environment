{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    env-load
    direnv
  ];

  env-load = pkgs.writeShellScriptBin "env-load" (builtins.readFile ../../resources/scripts/env-load);

in {
  home.packages = packages;

  targets.genericLinux.enable = true;
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupportedSystem = true;
}
