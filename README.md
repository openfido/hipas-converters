![master](https://github.com/openfido/hipas-converters/workflows/master/badge.svg)

# HiPAS Converters for OpenFIDO

This repository contains the OpenFIDO code needed to use the HiPAS converters.  To use these converters in OpenFIDO, do the following

1. Login to `https://app.openfido.org` in your favorite web browser
2. Click on `PIPELINES` on the left-side panel.
3. If `HiPAS Converters` is not displayed in the main panel, click on `+ Add Pipeline` on the top panel. Enter the **Pipeline Settings** below to create the pipeline, and click `Add Pipeline`.
4. Click `View Runs` for `HiPAS Converters`, and click `+ Start Runs`.  Upload your input files and click `Start Run`.  
5. When the run is complete, download the output files, or right-click to copy the link to use the URL endpoint in another tool.

## Pipeline settings

Pipeline Name

~~~
  HiPAS Converters
~~~

Description

~~~
  Collection of converters deployed in HiPAS
~~~

DockerHub Repository

~~~
  ubuntu:20.04
~~~

Git Clone URL (https)

~~~
  https://github.com/openfido/hipas-converters
~~~

Repository Branch

~~~
  master
~~~

Entrypoint Script (.sh)

~~~
  openfido.sh
~~~
