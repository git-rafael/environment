{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    marp
  ] ++ (with pkgs.python3Packages; [
    jupyterlab
    panel
    pandas
    altair
    influxdb
    kafka-python
    scikit-learn
  ]) ++ (with pkgs.pypyPackages; [
    jupyter_http_over_ws
    jupyter_bokeh
    ipython-sql
  ]);

in {
  home.packages = packages;
}
