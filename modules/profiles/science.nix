{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    marp
  ] ++ (with pkgs.python39Packages; [
    jupyterlab
    panel
    jupyter_http_over_ws
    jupyter_bokeh
    ipython-sql
    pandas
    altair
    influxdb
    kafka-python
    scikit-learn
  ]);

in {
  home.packages = packages;
}
