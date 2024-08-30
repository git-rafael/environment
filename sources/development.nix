{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  toWork = builtins.elem "work" features;
  
  devbox = edgePkgs.devbox;
  huggingface-cli = pkgs.python311.pkgs.huggingface-hub;

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

  code = edgePkgs.vscode.fhsWithPackages (ps: with ps; [ 
    zlib
    libsecret
    pkg-config
    openssl.dev

    nerdfonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji

    ollama
    quarto

    go
    jdk22
    rustup
    nodejs_18
    stdenv.cc
    dotnet-sdk_8
    (python312.withPackages (ps: with ps; [
      pip
      nbformat
      ipykernel
    ]))
  ]);
in {
  home.packages = with pkgs; [
    code
    devbox
    steampipe
    
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
  ] ++ pkgs.lib.optionals toWork [
    flash-install
  ];
}
