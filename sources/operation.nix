{ pkgs, edgePkgs, features, ... }:

let
  databricks-cli = pkgs.python3.pkgs.databricks-cli;

in {
  home.packages = with pkgs; [
    awscli
    saml2aws
    
    k9s
    kompose
    kubectl
    kubectx
    kafkactl
    minikube
    kubernetes-helm
    
    circleci-cli
    databricks-cli
    
    steampipe
  ];
}
