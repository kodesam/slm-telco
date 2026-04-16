#!/bin/bash
# 09_start_rag_api.sh — Install deps and start the RAG FastAPI service
set -e
echo "======================================"
echo " STEP 9: Start RAG API Service"
echo "======================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RAG_DIR="$PROJECT_ROOT/rag"
LOG_DIR="/tmp/slm-logs"
PID_FILE="/tmp/rag-api.pid"

mkdir -p "$RAG_DIR" "$LOG_DIR"

# Install Python dependencies
echo "→ Installing RAG API dependencies..."
python3.11 -m pip install --quiet \
  fastapi uvicorn chromadb \
  sentence-transformers langchain requests

# Write the RAG API script if not present
RAG_SCRIPT="$RAG_DIR/telecom_rag_api.py"
if [ ! -f "$RAG_SCRIPT" ]; then
  echo "→ Creating telecom_rag_api.py..."
  cat > "$RAG_SCRIPT" << 'PYEOF'
from fastapi import FastAPI
from pydantic import BaseModel
import chromadb, requests

app = FastAPI(title='Telecom SLM RAG API')

chroma_client = chromadb.HttpClient(host='localhost', port=8000)

OLLAMA_URL = 'http://localhost:11434/api/generate'
MODEL_NAME = 'telecom-slm'

try:
    collection = chroma_client.get_collection('telecom-ops')
    USE_RAG = True
except Exception:
    USE_RAG = False
    print("⚠️  Warning: telecom-ops collection not found. Running without RAG context.")

class Query(BaseModel):
    question: str
    top_k: int = 5

@app.get('/health')
def health():
    return {'status': 'ok', 'rag_enabled': USE_RAG, 'model': MODEL_NAME}

@app.post('/query')
def query_telecom_slm(q: Query):
    context = ""
    context_docs = []

    if USE_RAG:
        try:
            results = collection.query(query_texts=[q.question], n_results=q.top_k)
            context_docs = results['documents'][0]
            context = '\n'.join(context_docs)
        except Exception as e:
            context = ""

    if context:
        prompt = f"### Context from Telecom Knowledge Base:\n{context}\n\n### Instruction:\n{q.question}\n\n### Response:"
    else:
        prompt = f"### Instruction:\n{q.question}\n\n### Response:"

    resp = requests.post(OLLAMA_URL, json={
        'model': MODEL_NAME, 'prompt': prompt, 'stream': False
    }, timeout=120)

    return {
        'answer': resp.json()['response'],
        'rag_context_used': context_docs,
        'model': MODEL_NAME
    }
PYEOF
fi

# Kill existing RAG API process
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  kill "$OLD_PID" 2>/dev/null && echo "→ Stopped previous RAG API (PID $OLD_PID)" || true
  rm -f "$PID_FILE"
fi

echo "→ Starting RAG API on port 8080..."
cd "$RAG_DIR"
python3.11 -m uvicorn telecom_rag_api:app \
  --host 0.0.0.0 --port 8080 \
  --workers 1 \
  > "$LOG_DIR/rag-api.log" 2>&1 &

echo $! > "$PID_FILE"
sleep 3

# Verify
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
  echo ""
  echo "✅ DONE: RAG API running → http://localhost:8080"
  echo "   Docs  → http://localhost:8080/docs"
  echo "   Logs  → tail -f $LOG_DIR/rag-api.log"
  curl -s http://localhost:8080/health | python3.11 -m json.tool
else
  echo ""
  echo "⚠️  RAG API may still be starting. Check: tail -f $LOG_DIR/rag-api.log"
fi
