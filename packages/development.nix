{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;

  dind = pkgs.writeShellScriptBin "dind" (builtins.readFile ../resources/scripts/dind);
  using = pkgs.writeShellScriptBin "using" (builtins.readFile ../resources/scripts/using);

  quarto = pkgs.quarto.overrideAttrs (oldAttrs: {
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/share
        mv bin/* $out/bin
        mv share/* $out/share
        runHook preInstall
    '';
  });

  ipython = pkgs.writeShellApplication {
    name = "ipython";
    checkPhase = false;

    runtimeInputs = with pkgs; [ 
      python310
      stdenv.cc
      stdenv.cc.cc.lib
      python310Packages.pip 
    ];

    text = ''
      set -e;
      VENV_DIR=$HOME/.ipython-venv;
      if [ ! -d "$VENV_DIR" ]; then
        echo 'Creating ipython venv...';
        python -m venv $VENV_DIR;
        . $VENV_DIR/bin/activate;
        pip install -qq pip ipython ipython-sql --upgrade;
      else
        . $VENV_DIR/bin/activate;
      fi
      LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib" exec ipython "$@";
    '';
  };

  vscode-cli = edgePkgs.stdenv.mkDerivation rec {
    name = edgePkgs.vscode.name + "-cli";
    version = edgePkgs.vscode.version;
    system = edgePkgs.system;

    passthru = rec {
      arch = {
        x86_64-linux = "x64";
        aarch64-linux = "arm64";
      }.${system} or throwSystem;
      sha256 = {
        x86_64-linux = "sha256-7X6awCKNYRh2izs7tih9ORw1gJE1c+KBq4VbFlEECe8=";
        aarch64-linux = "sha256-lovi9Oj+/8y1Q2MPrJP5lGtX+NKcBVYHzURz5FLrtiw=";
      }.${system} or throwSystem;
      throwSystem = throw "Unsupported ${system} for ${name} v${version}";
    };

    src = edgePkgs.fetchzip {
      extension = "tar.gz";
      sha256 = passthru.sha256;
      url = "https://update.code.visualstudio.com/${version}/cli-alpine-${passthru.arch}/stable";
    };

    installPhase = ''
      mkdir -p $out/bin
      cp $src/code $out/bin
    '';
  };

  vscode = edgePkgs.writeShellApplication {
    name = "code";
    checkPhase = false;
    
    text = ''
      readonly CLI="${vscode-cli}/bin/code";
      ${if withUI then ''$CLI version use stable --install-dir ${edgePkgs.vscode}/lib/vscode >/dev/null;'' 
      else ''''}
      exec $CLI "$@";
    '';
  };

  packages = with pkgs; [
    devbox
    vscode

    ipython

    quarto
    httpie
    tldr
    gh

    docker-client
    docker-compose

    podman
    podman-compose

    git-crypt

    goss
    dgoss

    dind
    using

    packer
    terraform
  ];

in packages
