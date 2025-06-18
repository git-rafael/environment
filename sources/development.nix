{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  
  devbox = edgePkgs.devbox;
  huggingface-cli = pkgs.python3.pkgs.huggingface-hub;

  dind = pkgs.writeShellScriptBin "dind" (builtins.readFile ../resources/scripts/dind);
  using = pkgs.writeShellScriptBin "using" (builtins.readFile ../resources/scripts/using);

  flash-install = with pkgs; writeShellApplication {
    name = "flash-install";
    checkPhase = false;

    runtimeInputs = [ 
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
  
  
  ollama = edgePkgs.ollama;
  
  goose = with pkgs; let
    QT_QPA_PLATFORM_PLUGIN_PATH="${qt5.qtbase}/lib/qt-${qt5.qtbase.version}/plugins/platforms:${qt5.qtwayland}/lib/qt-${qt5.qtwayland.version}/plugins/platforms";
    python = python3.withPackages (ps: with ps; [
      pip
      cmake
      tkinter
      dbus-python
    ]);
    cli = buildFHSEnv {
      name = "goose";
      setLocale = "en_US.UTF-8";
      targetPkgs = pkgs: (with pkgs; [
        edgePkgs.goose-cli
        
        # Base dependencies
        uv
        nodejs
        python
        chromium
        stdenv.cc
        pkg-config
        
        # Build dependencies
        glib.dev
        dbus.dev
        openssl.dev
        
        # Runtime dependencies
        zlib
        glib
        dbus
        expat
        libnotify
        tesseract
        qt5.qtbase
        qt5.qtwayland
        
        # Graphics support
        mesa
        libGL
        wayland
        freetype
        fontconfig
        libxkbcommon
        
        # Audio support
        portaudio
        alsa-utils
      ]);
      
      runScript = "goose";
      profile = ''
        readonly VENV_DIR="$HOME/.goose/venv";
        if [ ! -d "$VENV_DIR" ]; then
          trap "rm -rf $VENV_DIR" ERR;
          echo "Creating virtual environment...";
          python -m venv "$VENV_DIR" && source "$VENV_DIR/bin/activate";
          pip install --quiet --no-input --no-cache-dir --upgrade --break-system-packages pip;
        else
          source "$VENV_DIR/bin/activate";
        fi
        
        export PUPPETEER_EXECUTABLE_PATH=${chromium}/bin/chromium;
        export QT_QPA_PLATFORM_PLUGIN_PATH=${QT_QPA_PLATFORM_PLUGIN_PATH};
      '';
    };
  in writeShellApplication {
    name = "goose";
    runtimeInputs = [ xorg.xhost cli ];
    text = ''${xorg.xhost}/bin/xhost +local: >/dev/null && exec ${cli}/bin/goose "$@"'';
  };
  
  code = edgePkgs.vscode.fhsWithPackages (ps: with ps; [ 
    zlib
    libsecret
    pkg-config
    openssl.dev
    
    go
    jdk
    rustup
    protobuf
    nodejs_22
    stdenv.cc
    dotnet-sdk_8
    nixfmt-rfc-style
    (python3.withPackages (ps: with ps; [
      pip
      nbformat
      ipykernel
    ]))
  ]);
in {
  home.packages = with pkgs; [
    code
    devenv
    quarto
    
    goose xorg.xhost
    ollama
    
    gh
    tldr
    httpie
    git-crypt
    huggingface-cli
    
    dind
    goss
    dgoss
    using
    podman
    docker-client
    podman-compose
    docker-compose
  ] ++ pkgs.lib.optionals forWork [
    flash-install
  ];
}
