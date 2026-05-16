#!/usr/bin/env bash
set -euo pipefail

echo "Starting FinQ backend on Render..."
echo "Ingesting knowledge base into ChromaDB..."
python -m backend.scripts.ingest_knowledge_base || {
  echo "Warning: knowledge base ingestion failed; backend will still start with degraded RAG."
}

exec uvicorn backend.app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
