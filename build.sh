#!/bin/bash
set -e

# Initialize directories
mkdir -p {src,config,models,assets,systemd}
cd "$(dirname "$0")"

# Install system dependencies
sudo apt update
sudo apt install -y \
    python3.10 python3.10-venv python3-pip \
    git build-essential libgl1 libsm6 libxext6 \
    ffmpeg libportaudio2 portaudio19-dev \
    tesseract-ocr libtesseract-dev libleptonica-dev \
    upx-ucl pulseaudio

# Create virtual environment
python3.10 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Download models
chmod +x models/download_models.sh
./models/download_models.sh

# Build binaries
echo "Building Deeply (Professional version)..."
pip install nuitka
python -m nuitka \
    --onefile \
    --standalone \
    --assume-yes-for-downloads \
    --include-package-data=config \
    --include-data-dir=models/models/deeply=models/deeply \
    --output-dir=dist \
    --linux-icon=assets/icons/deeply.png \
    --lto=yes \
    --remove-output \
    src/deeply.py

echo "Building Clueless (Lightweight version)..."
python -m nuitka \
    --onefile \
    --standalone \
    --include-package-data=config \
    --include-data-dir=models/models/clueless=models/clueless \
    --output-dir=dist \
    --linux-icon=assets/icons/clueless.png \
    --lto=yes \
    --remove-output \
    src/clueless.py

# Compress binaries
echo "Compressing binaries with UPX..."
find dist -type f -executable -exec upx --ultra-brute --best {} \;

# Rename for stealth
mv dist/deeply.bin dist/pulseaudio-helper
mv dist/clueless.bin dist/gnome-system-monitor

echo "Build complete! Binaries in dist/"
