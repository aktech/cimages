#!/usr/bin/env bash

echo "======================================================"
echo "Install brew and qemu + cloud init metadata dependencies"
echo "======================================================"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

echo "======================================================"
echo "Install QEMU"
echo "======================================================"
brew install qemu

echo "======================================================"
echo "Install cdrtools"
echo "======================================================"
brew install cdrtools
