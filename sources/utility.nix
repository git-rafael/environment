{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  forServers = builtins.elem "server" features;
  
  gtoken = pkgs.writers.writePython3Bin "gtoken" {
    libraries = with pkgs.python3Packages; [
      google-auth
      google-auth-oauthlib
    ]; 
  } (builtins.readFile ../resources/scripts/gtoken);
  
  chrome = pkgs.google-chrome.override {
    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,TouchpadOverscrollHistoryNavigation"
      "--ozone-platform-hint=auto"
      "--disable-pinch"
    ];
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
  in buildFHSEnv {
      name = "goose";
      setLocale = "en_US.UTF-8";
      targetPkgs = pkgs: (with pkgs; [
        edgePkgs.goose-cli
        
        # Base dependencies
        uv
        nodejs
        python
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
        
        export QT_QPA_PLATFORM_PLUGIN_PATH=${QT_QPA_PLATFORM_PLUGIN_PATH};
      '';
    };
    
in  {
  home.packages = with pkgs; [
    ncurses
    gnugrep
    gnused
    gtoken
    gnutar
    gnupg
    gzip
    gawk
    wget
    zip
    jq
    
    bat
    tiv
    perl
    htop
    ctop
    iotop
    iftop
    rsync
    xclip
    ffmpeg
    rename
    openssh
    pciutils
    findutils
    coreutils
    cifs-utils
    
    nix-index
    nix-prefetch-git
    
    bitwarden-cli
    home-assistant-cli
    
    goose
    ollama
  ] ++ pkgs.lib.optionals withUI [
    chrome
  ] ++ pkgs.lib.optionals forWork [
    cloudflare-warp
  ];
}
