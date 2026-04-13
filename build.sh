#!/bin/bash
set -e

echo "==> ScholarSpend AI - Build Script"
echo "==> Installing dependencies (wheels only, no compilation)..."
pip install --no-cache-dir --only-binary :all: -r requirements.txt

echo "==> Build complete!"
