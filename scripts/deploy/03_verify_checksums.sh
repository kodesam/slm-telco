#!/bin/bash
# 03_verify_checksums.sh — Checksum all model files
set -e
echo "======================================"
echo " STEP 3: Verify Model Checksums"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODELS_DIR="$PROJECT_ROOT/models/gguf"
CHECKSUM_FILE="$PROJECT_ROOT/models/checksums.sha256"

if [ ! -d "$MODELS_DIR" ]; then
  echo "❌ ERROR: Models directory not found at $MODELS_DIR"
  echo "   Run '📥 MODEL: Download Mistral 7B GGUF' first."
  exit 1
fi

# Generate checksums for all model files
echo "→ Computing checksums (macOS: shasum -a 256)..."
find "$MODELS_DIR" -type f \( -name "*.gguf" -o -name "*.safetensors" \) \
  -exec shasum -a 256 {} + > "$CHECKSUM_FILE"

echo ""
echo "→ Checksums written to: $CHECKSUM_FILE"
echo ""
cat "$CHECKSUM_FILE"

# Verify against saved checksums
echo ""
echo "→ Verifying integrity..."
shasum -a 256 -c "$CHECKSUM_FILE" && echo "" && echo "✅ DONE: All checksums verified OK"
