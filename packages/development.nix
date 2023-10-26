{ pkgs, edgePkgs, features }:

let
  withUI = builtins.elem "ui" features;
  toWork = builtins.elem "work" features;

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

  flash-install = pkgs.writeShellApplication {
    name = "flash-install";
    checkPhase = false;

    runtimeInputs = with pkgs; [ 
      gh
      busybox
    ];

    text = ''
      set -e;

      gh auth login --hostname github.com;
      readonly CTL_VERSION="$(gh release list --repo flash-tecnologia/flashstage.executable.flashctl | grep Latest | cut -f1 -)";
      gh release download $CTL_VERSION --pattern '*-linux' --output ~/.local/bin/flashctl --clobber --repo flash-tecnologia/flashstage.executable.flashctl;
      chmod +x ~/.local/bin/flashctl;
      readonly ADM_VERSION="$(gh release list --repo flash-tecnologia/flashstage.executable.flashadm | grep Latest | cut -f1 -)";
      gh release download $ADM_VERSION --pattern '*-linux' --output ~/.local/bin/flashadm --clobber --repo flash-tecnologia/flashstage.executable.flashadm;
      chmod +x ~/.local/bin/flashadm;

      readonly GH_TOKEN=$(gh auth token);
      if grep -q '^GH_TOKEN=' ~/.env 2>/dev/null; then
        sed -i 's/^GH_TOKEN=.*/GH_TOKEN='$GH_TOKEN'/' ~/.env;
      else
        echo 'GH_TOKEN='$GH_TOKEN >> ~/.env;
        chmod 600 ~/.env;
      fi
      export $GH_TOKEN;
    '';
  };

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

  vscode-cli = edgePkgs.stdenvNoCC.mkDerivation rec {
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

    phases = [ "unpackPhase" "installPhase" ];

    installPhase = ''
      mkdir -p $out/bin
      cp $src/code $out/bin
    '';
  };

  vscode = edgePkgs.writeShellApplication {
    name = "code";
    checkPhase = false;
    
    runtimeInputs = with pkgs; [ 
      vscode-cli
    ];

    text = ''
      ${pkgs.lib.optionalString withUI "code version use stable --install-dir ${edgePkgs.vscode}/lib/vscode >/dev/null;"}
      exec code "$@";
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
    python311Packages.huggingface-hub

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
  ] ++ pkgs.lib.optionals toWork [
    flash-install
  ];

in packages
