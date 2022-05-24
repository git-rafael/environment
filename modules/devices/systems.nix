{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    packer
    
    ansible
    terraform
    pulumi-bin

    gh
    circleci-cli

    awscli
    saml2aws

    k9s
    minikube
    kompose
    kubectl
    kubectx
    kubernetes-helm

    #kafkactl
  ];

in {  
  home.packages = packages;
}
