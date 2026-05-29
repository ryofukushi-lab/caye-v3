# ── Stage 1: Build frontend ──────────────────────────────
FROM node:20-slim AS frontend-build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY vite.config.ts tsconfig*.json ./
COPY src/ src/
RUN npm run build

# ── Stage 2: Python backend ──────────────────────────────
FROM python:3.11-slim
WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Install system dependencies for psycopg2-binary
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY backend/ backend/
COPY alembic/ alembic/
COPY alembic.ini .
COPY railway_start.sh .

# Copy built frontend from stage 1
COPY --from=frontend-build /app/dist/ dist/

EXPOSE ${PORT:-8000}

CMD ["bash", "railway_start.sh"]
