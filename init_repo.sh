#!/usr/bin/env bash
# DevOps Home Assignment – repo scaffold generator
# Usage: ./init_repo.sh <target‑directory>
set -euo pipefail

# -----------------------------------------------------------------
# -----------------------------------------------------------------
# -----------------------------------------------------------------
# 0. Ensure host prerequisites (Bun, unzip, Python³, Git) are present
# -----------------------------------------------------------------
PKGMGR="$(command -v apt-get || true)"  # empty on macOS

# 0.1 unzip (for Bun archive)
if ! command -v unzip &>/dev/null; then
  echo "📦  unzip not found – installing…"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install unzip
  else
    sudo apt-get update -y && sudo apt-get install -y unzip
  fi
fi

# 0.2 Bun
if ! command -v bun &>/dev/null; then
  echo "🛠  Bun not found – installing… (requires unzip)"
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# 0.3 Python 3 & pip
if ! command -v python3 &>/dev/null; then
  echo "🐍  Python3 not found – installing…"
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install python@3.12
  else
    sudo apt-get update -y && sudo apt-get install -y python3 python3-pip
  fi
fi

if ! command -v pip3 &>/dev/null; then
  echo "⚠️  pip3 missing even after Python install – abort"; exit 1;
fi

# 0.4 git
if ! command -v git &>/dev/null; then
  echo "❌ git is required but not installed. Aborting…"; exit 1;
fi

ROOT_DIR="${1:-devops-home-assignment}"
[ -d "$ROOT_DIR" ] && { echo "Directory $ROOT_DIR exists – abort."; exit 1; }
# ------------------------------------------------------------
# 1. Create directory skeleton
# ------------------------------------------------------------
mkdir -p "$ROOT_DIR"/{frontend/src/components,frontend/tests,backend/app,db,charts/{umbrella,frontend,backend,postgres},.github/workflows}

# ------------------------------------------------------------
# ------------------------------------------------------------
# 2. Frontend starter files (Bun + React + Vite)
# ------------------------------------------------------------
mkdir -p "$ROOT_DIR/frontend/src"
cat > "$ROOT_DIR/frontend/package.json" <<'EOF'
{
  "name": "frontend",
  "version": "0.0.1",
  "scripts": {
    "dev": "bun run vite --host",
    "build": "bun run vite build",
    "preview": "bun run vite preview",
    "test": "bun test"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.0.0"
  }
}
EOF

cat > "$ROOT_DIR/frontend/bunfig.toml" <<'EOF'
entry = "src/index.tsx"
outdir = "dist"
EOF

cat > "$ROOT_DIR/frontend/vite.config.ts" <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({
  plugins: [react()],
  server: { host: true, port: 3000 }
});
EOF

cat > "$ROOT_DIR/frontend/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "jsx": "react-jsx",
    "strict": true,
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
EOF
 <<'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";

const root = createRoot(document.getElementById("root")!);
root.render(<App />);
EOF

cat > "$ROOT_DIR/frontend/src/App.tsx" <<'EOF'
export default function App() {
  return (
    <div className="p-4 text-xl font-semibold">
      DevOps Home Assignment – React + Bun
    </div>
  );
}
EOF

cat > "$ROOT_DIR/frontend/src/api.ts" <<'EOF'
export async function fetchUsers() {
  const res = await fetch("/api/users");
  return res.json();
}
EOF

cat > "$ROOT_DIR/frontend/tests/App.test.tsx" <<'EOF'
import { expect, test } from "bun:test";

test("basic sanity", () => {
  expect(1 + 1).toBe(2);
});
EOF

cat > "$ROOT_DIR/frontend/Dockerfile" <<'EOF'
FROM oven/bun:1.0 AS build
WORKDIR /app
COPY . .
RUN bun install && bun run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# ------------------------------------------------------------
# 3. Backend starter files (FastAPI)
# ------------------------------------------------------------
cat > "$ROOT_DIR/backend/requirements.txt" <<'EOF'
fastapi
uvicorn[standard]
psycopg[binary]
SQLAlchemy>=2
python-dotenv
EOF

cat > "$ROOT_DIR/backend/app/main.py" <<'EOF'
from fastapi import FastAPI
from .database import engine, Base

app = FastAPI()

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}
EOF

cat > "$ROOT_DIR/backend/app/database.py" <<'EOF'
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/app")
engine = create_engine(DATABASE_URL, echo=False, future=True)
Base = declarative_base()
EOF

cat > "$ROOT_DIR/backend/Dockerfile" <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# ------------------------------------------------------------
# 4. Database init script
# ------------------------------------------------------------
cat > "$ROOT_DIR/db/init.sql" <<'EOF'
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name  TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
EOF

# ------------------------------------------------------------
# 5. Helm chart placeholders
# ------------------------------------------------------------
for chart in umbrella frontend backend postgres; do
  cat > "$ROOT_DIR/charts/$chart/Chart.yaml" <<EOF
apiVersion: v2
name: $chart
version: 0.1.0
EOF
done

# ------------------------------------------------------------
# 6. GitHub Workflows skeletons
# ------------------------------------------------------------
cat > "$ROOT_DIR/.github/workflows/ci.yml" <<'EOF'
name: CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Skeleton step
        run: echo "CI placeholder"
EOF

cat > "$ROOT_DIR/.github/workflows/cd.yml" <<'EOF'
name: CD
on:
  workflow_run:
    workflows: [CI]
    types: [completed]
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "CD placeholder"
EOF

# ------------------------------------------------------------
# 7. Misc files
# ------------------------------------------------------------
cat > "$ROOT_DIR/.dockerignore" <<'EOF'
**/__pycache__
*.pytest_cache
node_modules
bun.lockb
EOF

cat > "$ROOT_DIR/.env.example" <<'EOF'
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/app
EOF

cat > "$ROOT_DIR/Makefile" <<'EOF'
.PHONY: dev frontend backend test
frontend:
	cd frontend && bun run dev &
backend:
	cd backend && uvicorn app.main:app --reload &

dev: frontend backend

test:
	bun test && pytest -q
EOF

cat > "$ROOT_DIR/README.md" <<'EOF'
# DevOps Home Assignment (Scaffolded)

Run `./init_repo.sh <dir>` then follow README inside generated directory.
EOF

chmod +x "$ROOT_DIR/frontend/Dockerfile" "$ROOT_DIR/backend/Dockerfile"
chmod +x "$ROOT_DIR/init_repo.sh" || true

echo "
✅ Scaffold created at $ROOT_DIR"