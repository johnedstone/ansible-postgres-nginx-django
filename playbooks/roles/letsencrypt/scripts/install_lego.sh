#!/usr/bin/env bash
set -e

cd /tmp

curl -Ls https://api.github.com/repos/xenolf/lego/releases/latest | grep browser_download_url | grep linux_amd64 | cut -d '"' -f 4 | wget -i -
tar xf lego_v*_linux_amd64.tar.gz

sudo mv lego "$1/lego"

sudo rm /tmp/lego_v*

