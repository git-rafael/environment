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

  python = pkgs.python311.override {
    packageOverrides = self: super: {
      
      jupyter_http_over_ws = super.buildPythonPackage rec {
        pname = "jupyter_http_over_ws";
        version = "0.0.8";
        format = "wheel";
        python = "py2.py3";
        dist = python;
        src = super.fetchPypi {
          inherit pname version format python dist;
          sha256 = "sha256-MFKpSSnZ+0Hk/jP8IsVp6B4Bi5RUqSO9gYWZv2L/2Fo=";
        };
        buildInputs = with super;
          [ jupyter-packaging notebook ];
      };
      
      jupyter_bokeh = super.buildPythonPackage rec {
        pname = "jupyter_bokeh";
        version = "3.0.3";
        doCheck = false;
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-TEoGw/bF2SDINXaBvupXKXs9bR1GuCwpBFCIuW+dSwE=";
        };
        buildInputs = with super;
          [ jupyter-packaging ipywidgets bokeh ];
      };
    };
  };

  pythonPackages = python.withPackages (
    pythonPkgs: with pythonPkgs; [
      ipython
      ipython-sql
      jupyterlab
      jupyter_bokeh
      jupyter_http_over_ws
    ]
  );

  packages = with pkgs; [
    pythonPackages

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
