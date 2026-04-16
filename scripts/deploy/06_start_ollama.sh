#!/bin/bash
# 06_start_ollama.sh — Deploy Ollama container with GGUF model
set -e
echo "======================================"
echo " STEP 6: Start Ollama Container"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MODELS_DIR="$PROJECT_ROOT/models/gguf"
CONFIGS_DIR="$PROJECT_ROOT/configs"
MODELFILE="$CONFIGS_DIR/Modelfile"

# Create Modelfile if it doesn't exist
mkdir -p "$CONFIGS_DIR"
if [ ! -f "$MODELFILE" ]; then
  echo "→ Creating Modelfile..."
  cat > "$MODELFILE" << 'EOF'
FROM /models/mistral-7b-instruct-v0.2.Q4_K_M.gguf

PARAMETER temperature 0.1
PARAMETER top_p 0.9
PARAMETER num_ctx 4096
PARAMETER repeat_penalty 1.1

SYSTEM """You are an expert Telecom Network Operations assistant. \
You specialize in OSS/BSS operations, fault management, 5G/4G network \
configuration, alarm analysis, and CLI command generation for vendor \
platforms including Ericsson ENM, Nokia NetAct, and Huawei U2000. \
Always provide precise, actionable technical responses. \
When generating CLI commands, always specify the exact syntax."""

TEMPLATE """{{ if .System }}<|system|>
{{ .System }}</s>{{ end }}<|user|>
{{ .Prompt }}</s>
<|assistant|>
"""
EOF
  echo "→ Modelfile created at $MODELFILE"
fi

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q "^telecom-ollama$"; then
  echo "→ Removing existing telecom-ollama container..."
  docker rm -f telecom-ollama
fi

echo "→ Starting Ollama container..."
echo "   Models dir : $MODELS_DIR"
echo "   Configs dir: $CONFIGS_DIR"

docker run -d \
  --name telecom-ollama \
  -v "$MODELS_DIR":/models \
  -v "$CONFIGS_DIR":/configs \
  -p 127.0.0.1:11434:11434 \
  --restart unless-stopped \
  ollama/ollama:latest

echo "→ Waiting for Ollama to start..."
sleep 6

echo "→ Container logs:"
docker logs telecom-ollama 2>&1 | tail -8

echo ""
echo "✅ DONE: Ollama container running on http://localhost:11434"
