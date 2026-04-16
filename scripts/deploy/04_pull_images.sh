#!/bin/bash
# 04_pull_images.sh — Pull container images and save as .tar for air-gap bundle
set -e
echo "======================================"
echo " STEP 4: Pull + Save Container Images"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
IMAGES_DIR="$PROJECT_ROOT/container-images"

mkdir -p "$IMAGES_DIR"

# Check Docker is running
if ! docker info &>/dev/null; then
  echo "❌ ERROR: Docker is not running."
  echo "   Open Docker Desktop and wait for it to start, then re-run this task."
  exit 1
fi
echo "→ Docker is running ✓"

pull_and_save() {
  local IMAGE="$1"
  local TAG="$2"
  local OUTFILE="$3"

  if [ -f "$IMAGES_DIR/$OUTFILE" ]; then
    echo "→ $OUTFILE already exists — skipping pull"
  else
    echo "→ Pulling $IMAGE:$TAG ..."
    docker pull "$IMAGE:$TAG"
    echo "→ Saving to $IMAGES_DIR/$OUTFILE ..."
    docker save "$IMAGE:$TAG" -o "$IMAGES_DIR/$OUTFILE"
  fi
}

pull_and_save "ollama/ollama"       "latest"   "ollama-latest.tar"
pull_and_save "chromadb/chroma"     "0.4.24"   "chromadb-0.4.24.tar"
pull_and_save "prom/prometheus"     "v2.51.0"  "prometheus.tar"
pull_and_save "grafana/grafana"     "10.4.0"   "grafana.tar"

echo ""
echo "→ Image archive sizes:"
du -sh "$IMAGES_DIR"/*.tar

echo ""
echo "✅ DONE: All container images saved to $IMAGES_DIR"
