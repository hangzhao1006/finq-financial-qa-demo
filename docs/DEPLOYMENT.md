# Deployment Guide

This guide uses:

- Render for the FastAPI backend
- Vercel for the Next.js frontend

The GitHub repository can stay public, but never commit `.env`, raw PDFs, Chroma files, virtual environments, `node_modules`, or build outputs.

## 1. Push A Clean Repo

Before deploying, verify tracked files:

```bash
git status
git ls-files | grep -E '(\.env$|\.venv/|node_modules/|\.next/|\.chroma/|manual_reports/|raw_reports/|\.pdf$|\.docx$)' || true
```

The second command should print nothing.

## 2. Deploy Backend On Render

1. Go to Render.
2. Create a new Web Service.
3. Connect the GitHub repo.
4. Use the repo root as the root directory.
5. Render should detect `render.yaml`. If configuring manually:

```text
Environment: Python
Build command: pip install -r backend/requirements.txt
Start command: bash backend/start_render.sh
Health check path: /api/health
```

Set environment variables:

```text
OPENAI_API_KEY=your real key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini
FALLBACK_LLM_MODEL=gpt-3.5-turbo
EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-small
RERANK_PROVIDER=none
CHROMA_PERSIST_DIR=backend/.chroma
CACHE_BACKEND=memory
```

After deployment, test:

```text
https://your-render-service.onrender.com/api/health
https://your-render-service.onrender.com/docs
```

Notes:

- Render free tier may cold start slowly.
- `backend/start_render.sh` ingests `knowledge_base/**/*.md` into ChromaDB before starting the API.
- If ingestion fails, the backend still starts, but RAG quality may be degraded.

## 3. Deploy Frontend On Vercel

1. Go to Vercel.
2. Import the same GitHub repo.
3. Set Root Directory to:

```text
frontend
```

4. Framework preset: Next.js.
5. Build command:

```text
npm run build
```

6. Set environment variable:

```text
NEXT_PUBLIC_API_BASE_URL=https://your-render-service.onrender.com
```

Deploy and open the Vercel URL.

## 4. Smoke Test

Open the frontend and test:

```text
阿里巴巴当前股价是多少？
TSLA 最近 7 天涨跌如何？
华为2025年报的业务亮点是什么？
What risk factors are discussed in Apple's latest 10-K?
```

Also test the homepage asset card:

- Search `BABA`
- Switch chart tabs: `日内`, `7日`, `30日`

## 5. Common Issues

### Backend works locally but Render RAG returns no sources

Check Render logs for ingestion errors. Most likely causes:

- Missing `OPENAI_API_KEY`
- OpenAI embedding request failed during startup
- `knowledge_base/` was not committed

### Frontend cannot call backend

Check Vercel env:

```text
NEXT_PUBLIC_API_BASE_URL=https://your-render-service.onrender.com
```

Redeploy frontend after changing env vars.

### GitHub rejects push

Run:

```bash
git ls-files | grep -E '(\.env$|\.venv/|node_modules/|\.next/|\.chroma/|manual_reports/|raw_reports/|\.pdf$|\.docx$)' || true
```

Also scan for API keys:

```bash
grep -R "OPENAI_API_KEY=.*[A-Za-z0-9]" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv || true
```
