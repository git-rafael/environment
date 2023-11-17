{ pkgs, edgePkgs, features }:

let
  packages = with pkgs; let
    databricks-cli = python311.pkgs.databricks-cli;
  in [
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
  ];

in packages
