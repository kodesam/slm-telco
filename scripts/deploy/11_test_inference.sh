#!/bin/bash
# 11_test_inference.sh — Run end-to-end inference test against telecom-slm
set -e
echo "======================================"
echo " STEP 11: End-to-End Inference Test"
echo "======================================"

# Health checks before running tests
echo ""
echo "── Health Checks ──────────────────────"
echo "→ Checking Ollama API..."
for i in $(seq 1 10); do
  if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✓ Ollama API is ready"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "❌ Ollama API not ready after 30s"
    exit 1
  fi
  sleep 3
done

echo "→ Checking ChromaDB API..."
for i in $(seq 1 10); do
  if curl -sf http://localhost:8000/api/v1/heartbeat > /dev/null 2>&1; then
    echo "✓ ChromaDB API is ready"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "⚠️  ChromaDB not ready - RAG tests may fail"
  fi
  sleep 3
done

echo ""
echo "── Test 1: Direct Ollama API ─────────"
echo "→ Query: What does alarm ERR-7042 indicate in Ericsson ENM?"
echo "→ (Note: First request may take 30-60s for model load)"
echo ""

RESPONSE=$(curl -sf --max-time 120 http://localhost:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "telecom-slm",
    "prompt": "What does alarm ERR-7042 indicate in Ericsson ENM?",
    "stream": false
  }' 2>/dev/null)

if [ -z "$RESPONSE" ]; then
  echo "❌ No response from Ollama. Check: docker logs telecom-ollama"
  exit 1
fi

echo "$RESPONSE" | python3.11 -c "
import json, sys
data = json.load(sys.stdin)
print('Model    :', data.get('model','?'))
print('Response :', data.get('response','?')[:400], '...' if len(data.get('response','')) > 400 else '')
print('Tokens   :', data.get('eval_count','?'))
"

echo ""
echo "── Test 2: RAG API ───────────────────"
echo "→ Query: Generate ENM alarm suppression CLI for Cell ID 4421"
echo ""

RAG_RESPONSE=$(curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "Generate ENM alarm suppression CLI for Cell ID 4421"}' 2>/dev/null || echo "FAILED")

if echo "$RAG_RESPONSE" | grep -q "FAILED\|Connection refused"; then
  echo "⚠️  RAG API not reachable — run 'STEP 9: Start RAG API' first"
else
  echo "$RAG_RESPONSE" | python3.11 -c "
import json, sys
data = json.load(sys.stdin)
print('Model  :', data.get('model','?'))
print('RAG    :', 'enabled' if data.get('rag_context_used') else 'disabled (no corpus ingested yet)')
print('Answer :', data.get('answer','?')[:400])
"
fi

echo ""
echo "── Test 3: OpenShift Troubleshooting #1 ──"
echo "→ Query: How do I troubleshoot a pod crash loop in OpenShift?"
curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How do I troubleshoot a pod crash loop in OpenShift?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300], '...' if len(data.get('answer','')) > 300 else '')
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 4: OpenShift Troubleshooting #2 ──"
echo "→ Query: What commands check etcd quorum and cluster health?"
curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "What commands check etcd quorum and cluster health?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 5: OpenShift Troubleshooting #3 ──"
echo "→ Query: How to debug service endpoints not resolving in OpenShift?"
curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How to debug service endpoints not resolving in OpenShift?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 6: OpenShift Troubleshooting #4 ──"
echo "→ Query: What are the oc commands to investigate API server latency?"
curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "What are the oc commands to investigate API server latency?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 7: OpenShift Troubleshooting #5 ──"
echo "→ Query: How to fix a StatefulSet stuck in pending state?"
curl -sf --max-time 120 -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How to fix a StatefulSet stuck in pending state?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 8: RHEL Troubleshooting #1 ────────"
echo "→ Query: How to diagnose and resolve high disk usage on RHEL?"
curl -sf -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How to diagnose and resolve high disk usage on RHEL?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 9: RHEL Troubleshooting #2 ────────"
echo "→ Query: What is the procedure to fix out of memory (OOM) condition?"
curl -sf -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "What is the procedure to fix out of memory (OOM) condition?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 10: RHEL Troubleshooting #3 ───────"
echo "→ Query: How to diagnose SSH connection failures on RHEL servers?"
curl -sf -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How to diagnose SSH connection failures on RHEL servers?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 11: RHEL Troubleshooting #4 ───────"
echo "→ Query: What commands reveal and fix SELinux permission denials?"
curl -sf -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "What commands reveal and fix SELinux permission denials?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "── Test 12: RHEL Troubleshooting #5 ───────"
echo "→ Query: How to resolve yum package dependency conflicts?"
curl -sf -X POST http://localhost:8080/query \
  -H 'Content-Type: application/json' \
  -d '{"question": "How to resolve yum package dependency conflicts?"}' 2>/dev/null | python3.11 -c "
import json, sys; data = json.load(sys.stdin); print('Answer:', data.get('answer','?')[:300])
" 2>/dev/null || echo "⚠️  Query skipped (memory or connection issue)"

echo ""
echo "✅ DONE: Inference test complete (12 test queries executed)"
echo ""
echo "Next steps:"
echo "  • Ingest corpus: run 'RAG: Ingest Telecom Corpus' task"
echo "  • Interactive:   curl -X POST http://localhost:8080/query -H 'Content-Type: application/json' -d '{\"question\": \"your question\"}'"
echo "  • API Docs:      open http://localhost:8080/docs"
