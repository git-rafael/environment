{ pkgs, edgePkgs, features }:

let
  packages = with pkgs; [
    ansible

    awscli
    saml2aws

    k9s
    minikube
    kompose
    kubectl
    kubectx
    kubernetes-helm

    kafkactl

    circleci-cli

    steampipe

    python311.pkgs.databricks-cli
  ];

in packages
