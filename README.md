# Telecom SLM — VS Code Deployment Tasks

## Setup

1. Copy the `.vscode/` folder and `scripts/` folder into your project root (`telco-slm/`)
2. Open the project in VS Code: `code .`
3. Open Command Palette: `Cmd+Shift+P` → **Tasks: Run Task**

## Task Order (Full Deploy)

Run **🚀 FULL DEPLOY: Run Complete Pipeline** to execute all steps automatically, or run individually:

| Task | What it does |
|------|-------------|
| 🐍 SETUP: Install Python 3.11 + pip | Installs Python, bootstraps pip, installs hf CLI |
| 📥 MODEL: Download Mistral 7B GGUF | Downloads ~4.1GB GGUF via `hf` CLI |
| ✅ MODEL: Verify Checksums | Runs `shasum -a 256` on all model files |
| 🐳 DOCKER: Pull + Save Container Images | Pulls Ollama, ChromaDB, Prometheus, Grafana |
| 🐳 DOCKER: Load Images from Bundle | Loads .tar images into Docker (air-gap mode) |
| 🤖 OLLAMA: Start Ollama Container | Starts Ollama with your GGUF model mounted |
| 🤖 OLLAMA: Register Telecom SLM Model | Creates `telecom-slm` model from Modelfile |
| 🧠 CHROMADB: Start ChromaDB Container | Starts ChromaDB vector DB on port 8000 |
| 🚀 RAG API: Start Service | Installs FastAPI deps, starts RAG API on port 8080 |
| ❤️  HEALTH: Check All Services | Verifies all endpoints are responding |
| 🧪 TEST: Run Inference Test | Runs a test query end-to-end |

## Keyboard Shortcut

`Cmd+Shift+B` runs the default build task (Full Deploy).

## Ports

| Service | URL |
|---------|-----|
| Ollama | http://localhost:11434 |
| ChromaDB | http://localhost:8000 |
| RAG API | http://localhost:8080 |
| API Docs | http://localhost:8080/docs |
# slm-telco
