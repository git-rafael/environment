{ config, lib, pkgs, ... }:

let
  javaPackages = import ../packages/java.nix pkgs;
  dotnetPackages = import ../packages/dotnet.nix pkgs;
  pythonPackages = import ../packages/python.nix pkgs;
  javascriptPackages = import ../packages/javascript.nix pkgs;

  packages = with pkgs; [
    tldr
    
    docker
    docker-compose

    podman
    podman-compose

    git
    git-lfs
    git-crypt
    git-hound

    pritunl-ssh

    goss
    dgoss
  ]
  ++ javaPackages
  ++ dotnetPackages
  ++ pythonPackages
  ++ javascriptPackages;

in {
  home.packages = packages;
}
