
[![RootDB](https://www.rootdb.fr/assets/logo_name_blue_500x250.png)]()

# RootDB - documentation repository

You'll find everything related to the official RootDB documentation available at [documentation.rootdb.fr](https://documentation.rootdb.fr)


<!-- TOC -->
* [RootDB - documentation repository](#rootdb---documentation-repository)
* [Sphinx installation](#sphinx-installation)
  * [opensuse](#opensuse)
  * [fedora](#fedora)
  * [debian](#debian)
  * [ubuntu](#ubuntu)
* [Build documentation](#build-documentation)
<!-- TOC -->

* The documentation is generated with [Sphinx](https://www.sphinx-doc.org)

# Sphinx installation
## opensuse

```bash
sudo zypper in -y make python310-pip python310-Sphinx python310-readthedocs-sphinx-ext  python310-sphinx-inline-tabs  python310-sphinx-tabs python310-sphinxcontrib-fulltoc
pip install sphinxcontrib-images
```

## fedora

```bash  
sudo dnf install -y make python3-pip python3-sphinx python3-sphinx-inline-tabs  python3-sphinx-tabs python3-sphinx_rtd_theme
pip install sphinxcontrib-images
```

## debian

```bash
sudo apt install -y make python3-pip python3-sphinx python3-sphinx-tabs sphinx-rtd-theme-common
pip install sphinxcontrib-images
```

## ubuntu

```bash
sudo make python3-pip python3-sphinx sphinx-rtd-theme-common
pip install sphinxcontrib-images
```
# Build documentation

```bash
make html
```
