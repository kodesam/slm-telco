#!/bin/bash
# 10_health_check.sh — Check all services are running
echo "======================================"
echo " STEP 10: Health Check — All Services"
echo "======================================"

PASS=0
FAIL=0

check() {
  local NAME="$1"
  local CMD="$2"
  local EXPECT="$3"

  RESULT=$(eval "$CMD" 2>/dev/null || echo "FAILED")
  if echo "$RESULT" | grep -q "$EXPECT"; then
    echo "  ✅ $NAME"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $NAME — got: $RESULT"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "── Containers ────────────────────────"
check "telecom-ollama running"   "docker ps --filter name=telecom-ollama --format '{{.Status}}'"   "Up"
check "telecom-chromadb running" "docker ps --filter name=telecom-chromadb --format '{{.Status}}'" "Up"

echo ""
echo "── APIs ──────────────────────────────"
check "Ollama API"    "curl -sf http://localhost:11434/api/tags"          "models"
check "ChromaDB API"  "curl -sf http://localhost:8000/api/v1/heartbeat"   "nanosecond"
check "RAG API"       "curl -sf http://localhost:8080/health"             "ok"

echo ""
echo "── Models ────────────────────────────"
check "telecom-slm registered" "docker exec telecom-ollama ollama list 2>/dev/null" "telecom-slm"

echo ""
echo "── Summary ───────────────────────────"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "✅ ALL SYSTEMS GO — Full stack is healthy"
else
  echo ""
  echo "⚠️  $FAIL check(s) failed. Run the relevant deploy step to fix."
fi

echo ""
echo "── Container Stats ───────────────────"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || true
