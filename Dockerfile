# Multi-stage build for production-ready Flask + Angular app

# Stage 1: Build Angular Frontend
FROM oven/bun:1-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy package files
COPY frontend/package.json frontend/bun.lock* ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy frontend source
COPY frontend/ .

# Build Angular app for production
RUN bun run build -- --configuration production

# Stage 2: Build Python Backend
FROM python:3.11-slim AS backend-builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependency files
COPY pyproject.toml ./

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir uv && \
    uv pip install --system -r pyproject.toml

# Stage 3: Final Runtime Image
FROM python:3.11-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder
COPY --from=backend-builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=backend-builder /usr/local/bin /usr/local/bin

# Copy backend code
COPY backend/ ./backend/

# Copy built frontend from frontend-builder
COPY --from=frontend-builder /app/frontend/dist ./dist

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    FLASK_APP=backend.main \
    FLASK_ENV=production \
    PORT=5000

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Run the application
CMD ["python", "-m", "backend.main"]
