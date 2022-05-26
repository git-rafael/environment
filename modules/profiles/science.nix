{ config, lib, pkgs, ... }:

let
  myPyPkgs = pkgs.python38Packages.override {

    overrides = self: super: {

      jupyter-packaging = super.buildPythonPackage rec {
        pname = "jupyter-packaging";
        version = "0.12.0";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-ujsDL1KgOdnl7Y9sUPP5oA3LlwBYccJGc6OzoFRlrvU=";
        };
      };

      jupyter_http_over_ws = super.buildPythonPackage rec {
        pname = "jupyter_http_over_ws";
        version = "0.0.8";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-sKoeeQLTgIppjUhT9t/hL9AqDZyzhR2zv1lwMQbUSoA=";
        };
        buildInputs = with super;
          [ jupyter-packaging ];
      };
      
      jupyter_bokeh = super.buildPythonPackage rec {
        pname = "jupyter_bokeh";
        version = "3.0.4";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-ujsDL1KgOdnl7Y9sUPP5oA3LlwBYccJGc6OzoFRlrvU=";
        };
        buildInputs = with super;
          [ jupyter-packaging ];
      };

      ipython-sql = super.buildPythonPackage rec {
        pname = "ipython-sql";
        version = "0.4.0";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-PoiOWb9XJ3y9bzg8sjKFiy18cSGeV0klcSjxbZhX5Gw=";
        };
        buildInputs = with super;
          [ jupyterlab ];
      };
    };
  };

  packages = with pkgs; [
    marp
  ] ++ (with myPyPkgs; [
    jupyterlab
    panel
    pyspark
    pandas
    numpy
    scipy
    patsy
    altair
    influxdb
    statsmodels
    scikit-learn
    kafka-python
    jupyter_http_over_ws
    jupyter_bokeh
    # ipython-sql
  ]);

in {
  home.packages = packages;
}
