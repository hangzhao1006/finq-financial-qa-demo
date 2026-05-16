# 部署指南

本文档说明如何用最简单的方式部署 FinQ：

- 后端：Render，运行 FastAPI
- 前端：Vercel，运行 Next.js

GitHub 仓库可以是 public，但不要提交 `.env`、原始 PDF、Chroma 向量库、虚拟环境、`node_modules` 或构建产物。

## 1. 部署前检查仓库

先确认 Git 当前没有不该提交的文件：

```bash
git status
git ls-files | grep -E '(\.env$|\.venv/|node_modules/|\.next/|\.chroma/|manual_reports/|raw_reports/|\.pdf$|\.docx$)' || true
```

第二条命令正常情况下应该没有输出。

当前推荐使用这个 GitHub 仓库部署：

```text
https://github.com/hangzhao1006/finq-financial-qa-demo
```

## 2. 在 Render 部署后端

1. 打开 Render。
2. 创建一个新的 `Web Service`。
3. 连接 GitHub 仓库 `finq-financial-qa-demo`。
4. Root Directory 使用仓库根目录，不要填 `backend`。
5. Render 应该会自动识别根目录的 `render.yaml`。

如果你选择手动配置，使用：

```text
Environment: Python
Build command: pip install -r backend/requirements.txt
Start command: bash backend/start_render.sh
Health check path: /api/health
```

### Render 环境变量

在 Render 的 Environment 页面填：

```text
OPENAI_API_KEY=你的真实 OpenAI API key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_MODEL=gpt-4o-mini
FALLBACK_LLM_MODEL=gpt-3.5-turbo
EMBEDDING_PROVIDER=openai
EMBEDDING_MODEL=text-embedding-3-small
RERANK_PROVIDER=none
CHROMA_PERSIST_DIR=backend/.chroma
CACHE_BACKEND=memory
```

`OPENAI_API_KEY` 不要写进 GitHub，只在 Render 后台填。

### 后端部署后测试

假设你的 Render 地址是：

```text
https://your-render-service.onrender.com
```

测试：

```text
https://your-render-service.onrender.com/api/health
https://your-render-service.onrender.com/docs
```

如果 `/api/health` 能打开，说明后端已经启动。

### Render 注意事项

- Render 免费版会冷启动，第一次打开可能较慢。
- `backend/start_render.sh` 会在启动 API 之前执行一次知识库导入，把 `knowledge_base/**/*.md` 写入 ChromaDB。
- 如果知识库导入失败，后端仍会启动，但 RAG 质量可能下降。
- 如果日志里看到 OpenAI embedding 失败，财报 RAG 仍可能通过 lexical fallback 工作，但回答质量会更保守。

## 3. 在 Vercel 部署前端

1. 打开 Vercel。
2. Import 同一个 GitHub 仓库。
3. Root Directory 填：

```text
frontend
```

4. Framework Preset 选择 `Next.js`。
5. Build Command 使用：

```text
npm run build
```

6. 在 Vercel 环境变量中添加：

```text
NEXT_PUBLIC_API_BASE_URL=https://your-render-service.onrender.com
```

这里要换成你自己的 Render 后端地址。

修改 Vercel 环境变量后，需要重新部署一次前端。

## 4. 部署后冒烟测试

打开 Vercel 前端地址，测试这些问题：

```text
阿里巴巴当前股价是多少？
TSLA 最近 7 天涨跌如何？
华为2025年报的业务亮点是什么？
What risk factors are discussed in Apple's latest 10-K?
```

也测试首页资产卡片：

- 搜索 `BABA`
- 切换图表：`日内`、`7日`、`30日`
- 确认价格、走势线、趋势标签能显示

## 5. 常见问题

### 5.1 后端本地能跑，但 Render 上 RAG 没有来源

去 Render Logs 看 `ingest_knowledge_base` 是否失败。

常见原因：

- 没有填 `OPENAI_API_KEY`
- OpenAI embedding 请求失败
- `knowledge_base/` 没有提交到 GitHub
- Chroma 写入失败

### 5.2 前端页面能打开，但问答请求失败

检查 Vercel 环境变量：

```text
NEXT_PUBLIC_API_BASE_URL=https://your-render-service.onrender.com
```

注意不要在末尾加 `/api`。

正确：

```text
https://your-render-service.onrender.com
```

错误：

```text
https://your-render-service.onrender.com/api
```

改完后重新部署 Vercel。

### 5.3 Render 后端第一次访问很慢

这是免费版冷启动，正常。等几十秒后再刷新。

### 5.4 GitHub push 又被拒绝

先检查是否有不该提交的文件：

```bash
git ls-files | grep -E '(\.env$|\.venv/|node_modules/|\.next/|\.chroma/|manual_reports/|raw_reports/|\.pdf$|\.docx$)' || true
```

再检查是否有 API key：

```bash
grep -R "OPENAI_API_KEY=.*[A-Za-z0-9]" . \
  --exclude=.env \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  --exclude-dir=.venv \
  --exclude-dir=.next \
  || true
```

如果 GitHub 提示某个旧 commit 里有 secret，需要重新创建无旧历史的 clean root commit，而不是只改最新 commit。

### 5.5 不想别人拿到源码怎么办

如果 GitHub repo 是 public，就不能禁止 clone 或下载。  
想只展示效果，最好的方式是只分享 Vercel 前端链接，不分享 GitHub 仓库链接。

## 6. 推荐分享方式

给别人看 demo 时，优先发：

```text
Vercel 前端链接
```

如果对方需要查看代码，再发：

```text
GitHub repo 链接
```

当前 repo 已经通过 `.gitignore` 排除了 `.env`、PDF、Chroma、venv、node_modules 和构建产物。
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
