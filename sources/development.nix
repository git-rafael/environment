{ pkgs, edgePkgs, features, ... }:

let
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
    distrobox
    just
  ] ++ pkgs.lib.optionals forWork [
    flash-install
  ];
}
