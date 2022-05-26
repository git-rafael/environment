{ config, lib, pkgs, ... }:

let
  pythonPkgs = pkgs.python38Packages.override {

    overrides = self: super: {

      jupyter_http_over_ws = super.buildPythonPackage rec {
        pname = "jupyter_http_over_ws";
        version = "0.0.8";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-sKoeeQLTgIppjUhT9t/hL9AqDZyzhR2zv1lwMQbUSoA=";
        };
        buildInputs = with super;
          [ jupyter-packaging notebook ];
      };
      
      jupyter_bokeh = super.buildPythonPackage rec {
        pname = "jupyter_bokeh";
        version = "3.0.3";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-TEoGw/bF2SDINXaBvupXKXs9bR1GuCwpBFCIuW+dSwE=";
        };
        checkPhase = ''
          py.test -k 'not function_name and not other_function' tests
        '';
        buildInputs = with super;
          [ jupyter-packaging ipywidgets bokeh ];
      };

      ipython-sql = super.buildPythonPackage rec {
        pname = "ipython-sql";
        version = "0.4.0";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-PoiOWb9XJ3y9bzg8sjKFiy18cSGeV0klcSjxbZhX5Gw=";
        };
      };
    };
  };

  packages = with pkgs; [
    marp
  ] ++ (with pythonPkgs; [
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
