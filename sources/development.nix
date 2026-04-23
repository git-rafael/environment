{ pkgs, edgePkgs, features, ... }:

let
  withUI = builtins.elem "ui" features;
  forWork = builtins.elem "work" features;
  
  ollama = edgePkgs.ollama;

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
    
    nodejs_22

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
