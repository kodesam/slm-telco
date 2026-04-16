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
