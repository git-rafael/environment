pkgs:

let
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

  packages = with pkgs; [
    devbox

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
