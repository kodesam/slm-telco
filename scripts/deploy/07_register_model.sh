#!/bin/bash
# 07_register_model.sh — Register telecom-slm in Ollama from Modelfile
set -e
echo "======================================"
echo " STEP 7: Register Telecom SLM Model"
echo "======================================"

# Wait for Ollama API to be ready
echo "→ Waiting for Ollama API..."
for i in $(seq 1 15); do
  if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "→ Ollama API is ready ✓"
    break
  fi
  echo "   Attempt $i/15 — retrying in 3s..."
  sleep 3
done

if ! curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
  echo "❌ ERROR: Ollama API not reachable after 45s"
  echo "   Check: docker logs telecom-ollama"
  exit 1
fi

echo "→ Registering telecom-slm model from Modelfile..."
docker exec telecom-ollama ollama create telecom-slm -f /configs/Modelfile

echo ""
echo "→ Registered models:"
docker exec telecom-ollama ollama list

echo ""
echo "✅ DONE: telecom-slm model registered in Ollama"
