#!/bin/bash
set -e

echo "==> ScholarSpend AI - Build Script"
echo "==> Installing dependencies with pip..."
pip install --upgrade pip
pip install -r requirements.txt

echo "==> Build complete!"
