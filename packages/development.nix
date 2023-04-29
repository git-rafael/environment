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

  packages = with pkgs; [
    devbox

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
