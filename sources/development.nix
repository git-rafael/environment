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

    text = builtins.readFile ../resources/scripts/flash-install;
  };
  
  ollama = edgePkgs.ollama;

  openwork = pkgs.stdenv.mkDerivation rec {
    pname = "openwork";
    version = "0.11.137";

    src = pkgs.fetchurl {
      url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-desktop-linux-amd64.deb";
      hash = "sha256-vGApxKr86ITTpghPaqUkqYnURPoKw2mVRqvH0jlJbqo=";
    };

    nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      cairo
      gdk-pixbuf
      glib
      gtk3
      gsettings-desktop-schemas
      libsoup_3
      webkitgtk_4_1
    ];

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      mkdir -p $out
      cp -r usr/bin $out/
      cp -r usr/share $out/
    '';

    meta.mainProgram = "openwork";
  };

  goose = with pkgs; let
    QT_QPA_PLATFORM_PLUGIN_PATH="${qt5.qtbase}/lib/qt-${qt5.qtbase.version}/plugins/platforms:${qt5.qtwayland}/lib/qt-${qt5.qtwayland.version}/plugins/platforms";
    python = python3.withPackages (ps: with ps; [
      pip
      cmake
      tkinter
      dbus-python
    ]);
    cli = let
      GOOSE_PATH = ''$HOME/.local'';
      GOOSE_VENV = "${GOOSE_PATH}/share/goose/venv";
      GOOSE_BIN = "${GOOSE_PATH}/bin/goose";
    in buildFHSEnv {
      name = "goose";
      setLocale = "en_US.UTF-8";
      targetPkgs = pkgs: (with pkgs; [
        #edgePkgs.goose-cli
        
        # Base dependencies
        uv
        nodejs
        python
        chromium
        stdenv.cc
        pkg-config
        edgePkgs.mcp-proxy
        
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
      ] ++ pkgs.lib.optionals withUI [
        # Graphics support
        mesa
        libGL
        wayland
        freetype
        fontconfig
        libxkbcommon
        
        xorg.libxcb
        
        qt5.qtbase
        qt5.qtwayland
        
        # Audio support
        portaudio
        alsa-utils
      ]);
      
      runScript = "${GOOSE_BIN}";
      profile = ''
        test -f ${GOOSE_BIN} || ${curl}/bin/curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash;
      
        readonly VENV_DIR="${GOOSE_VENV}";
        if [ ! -d "$VENV_DIR" ]; then
          trap "rm -rf $VENV_DIR" ERR;
          echo "Creating virtual environment...";
          ${python}/bin/python -m venv "$VENV_DIR" && source "$VENV_DIR/bin/activate";
          pip install --quiet --no-input --no-cache-dir --upgrade --break-system-packages pip;
        else
          source "$VENV_DIR/bin/activate";
        fi
        
        ${if withUI then ''
        export QT_QPA_PLATFORM_PLUGIN_PATH=${QT_QPA_PLATFORM_PLUGIN_PATH};
        '' else ''
        export PUPPETEER_HEADLESS=true;
        ''}
        export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true;
        export PUPPETEER_EXECUTABLE_PATH=${chromium}/bin/chromium;
      '';
    };
  in writeShellApplication {
    name = "goose";
    runtimeInputs = [ xorg.xhost cli ];
    text = if withUI then ''${xorg.xhost}/bin/xhost +local: >/dev/null && exec ${cli}/bin/goose "$@"''
                      else ''exec ${cli}/bin/goose "$@"'';
  };

  code = edgePkgs.vscodium.fhsWithPackages (ps: with ps; [
    zlib
    libsecret
    pkg-config
    openssl.dev

    go
    jdk
    rustup
    nixfmt
    protobuf
    nodejs_22
    stdenv.cc
    dotnet-sdk_8
    (python3.withPackages (ps: with ps; [
      pip
      nbformat
      ipykernel
    ]))
  ]);
in {
  home.file = {
    ".config/VSCodium/product.json" = {
      force = true;
      text = builtins.toJSON {
        extensionsGallery = {
          serviceUrl = "https://marketplace.visualstudio.com/_apis/public/gallery";
          itemUrl = "https://marketplace.visualstudio.com/items";
        };
      };
    };
  };
  
  home.packages = with pkgs; [
    code
    devenv
    quarto
    
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
  ] ++ pkgs.lib.optionals withUI [
    openwork
  ] ++ pkgs.lib.optionals forWork [
    flash-install
  ];
}
