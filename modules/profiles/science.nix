{ config, lib, pkgs, ... }:

let
  myPyPkgs = pkgs.python3Packages.override {
    overrides = self: super: {
      righteuous-fa = super.buildPythonPackage rec {
        pname = "righteous-fa";
        version = "1.2.1";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "1qrbk8v2bxm8k6knx33vajajs8y2lsn77j4byviy7mh354xwzsc4";
        };
        buildInputs = with super;
          [ pandas numpy statsmodels scikitlearn scipy patsy ];
      };
      impetuous-gfa = super.buildPythonPackage rec {
        pname = "impetuous-gfa";
        version = "0.95.1";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "11vd8lk6bj9j4xhhqrclvwk8bwh47svracwzcslww7sf16wiz4f3";
        };
        buildInputs = with super;
          [ pandas numpy statsmodels scikitlearn scipy patsy ];
      };
      pypi-matplotlib = super.buildPythonPackage rec {
        pname = "matplotlib";
        version = "3.3.3";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "1v5xwk8amb9b8lx383yy0mgkvzbnfh9d7c4arzjykky4frj0rdmi";
        };
        buildInputs = with super;
          [ numpy certifi ];
      };
      counterpartner = super.buildPythonPackage rec {
        pname = "counterpartner";
        version = "0.10.2";
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "0sfc59ycpq2j4y0c8k002h23arz6kidbvamhlmxfgrj38kxry0nx";
        };
        buildInputs = with super;
          [ pandas numpy statsmodels scikitlearn scipy ];
      };
    };
  };

  packages = with pkgs; [
    marp
  ] ++ (with myPyPkgs; [
    jupyterlab
    panel
    pypi-matplotlib
    # pandas
    # altair
    # influxdb
    # kafka-python
    # scikit-learn
    # jupyter_http_over_ws
    # jupyter_bokeh
    # ipython-sql
  ]);

in {
  home.packages = packages;
}
