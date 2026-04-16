#!/bin/bash
# 05_load_images.sh — Load container images from air-gap bundle
set -e
echo "======================================"
echo " STEP 5: Load Container Images"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGES_DIR="$PROJECT_ROOT/container-images"

if ! docker info &>/dev/null; then
  echo "❌ ERROR: Docker is not running. Open Docker Desktop first."; exit 1
fi

for TAR in "$IMAGES_DIR"/*.tar; do
  if [ -f "$TAR" ]; then
    echo "→ Loading $(basename "$TAR") ..."
    docker load -i "$TAR"
  fi
done

echo ""
echo "→ Loaded images:"
docker images

echo ""
echo "→ Tagging images for local use..."
docker tag ollama/ollama:latest localhost/telecom-ollama:1.0 2>/dev/null && echo "  Tagged: telecom-ollama:1.0" || true
docker tag chromadb/chroma:0.4.24 localhost/telecom-chromadb:1.0 2>/dev/null && echo "  Tagged: telecom-chromadb:1.0" || true

echo ""
echo "✅ DONE: All images loaded and tagged"
