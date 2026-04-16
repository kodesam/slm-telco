#!/bin/bash
# 08_start_chromadb.sh — Deploy ChromaDB container for RAG
set -e
echo "======================================"
echo " STEP 8: Start ChromaDB Container"
echo "======================================"

RAG_DATA_DIR="/tmp/slm-rag/chromadb-data"
mkdir -p "$RAG_DATA_DIR"
echo "→ ChromaDB data dir: $RAG_DATA_DIR"

# Remove existing container
if docker ps -a --format '{{.Names}}' | grep -q "^telecom-chromadb$"; then
  echo "→ Removing existing telecom-chromadb container..."
  docker rm -f telecom-chromadb
fi

echo "→ Starting ChromaDB container..."
docker run -d \
  --name telecom-chromadb \
  -v "$RAG_DATA_DIR":/chroma/chroma \
  -p 8000:8000 \
  -e IS_PERSISTENT=TRUE \
  -e PERSIST_DIRECTORY=/chroma/chroma \
  --restart unless-stopped \
  chromadb/chroma:0.4.24

echo "→ Waiting for ChromaDB to start..."
sleep 5

# Health check
HEARTBEAT=$(curl -sf http://localhost:8000/api/v1/heartbeat 2>/dev/null || echo "FAILED")
echo "→ ChromaDB heartbeat: $HEARTBEAT"

if echo "$HEARTBEAT" | grep -q "nanosecond"; then
  echo ""
  echo "✅ DONE: ChromaDB running on http://localhost:8000"
else
  echo ""
  echo "⚠️  WARNING: ChromaDB may still be starting. Check: docker logs telecom-chromadb"
fi
