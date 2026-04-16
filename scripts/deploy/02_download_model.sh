#!/bin/bash
# 02_download_model.sh — Download Mistral 7B GGUF via hf CLI
set -e
echo "======================================"
echo " STEP 2: Download Mistral 7B GGUF"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODELS_DIR="$PROJECT_ROOT/models/gguf"

mkdir -p "$MODELS_DIR"
echo "→ Models directory: $MODELS_DIR"

# Resolve hf CLI (handles PATH differences across shells)
HF_CLI=""
for candidate in hf "$HOME/.local/bin/hf" "$(python3.11 -m site --user-base)/bin/hf"; do
  if command -v "$candidate" &>/dev/null 2>&1 || [ -f "$candidate" ]; then
    HF_CLI="$candidate"
    break
  fi
done

if [ -z "$HF_CLI" ]; then
  echo "→ hf CLI not found — installing huggingface_hub..."
  python3.11 -m pip install --upgrade huggingface_hub
  HF_CLI="$(python3.11 -m site --user-base)/bin/hf"
fi

GGUF_FILE="$MODELS_DIR/mistral-7b-instruct-v0.2.Q4_K_M.gguf"

if [ -f "$GGUF_FILE" ]; then
  SIZE=$(du -sh "$GGUF_FILE" | cut -f1)
  echo "→ GGUF already exists ($SIZE) — skipping download"
  echo "   Delete $GGUF_FILE to re-download"
else
  echo "→ Downloading Mistral 7B Q4_K_M GGUF (~4.1 GB)..."
  echo "   This will take several minutes depending on your connection."
  "$HF_CLI" download TheBloke/Mistral-7B-Instruct-v0.2-GGUF \
    mistral-7b-instruct-v0.2.Q4_K_M.gguf \

    --local-dir "$MODELS_DIR"
fi

echo ""
echo "✅ DONE: Model ready at $GGUF_FILE"
ls -lh "$GGUF_FILE"
