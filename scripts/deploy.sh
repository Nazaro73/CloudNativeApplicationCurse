#!/bin/bash
# Deploy script for Gym Management System
# This script is idempotent - can be run multiple times safely

set -e

IMAGE_TAG="${1:-latest}"

echo "========================================"
echo "  Deploying Gym Management System"
echo "  Image Tag: $IMAGE_TAG"
echo "========================================"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

echo ""
echo "[1/4] Stopping existing containers..."
docker compose -f docker-compose.prod.yml down || true

echo ""
echo "[2/4] Pulling latest images from GHCR..."
docker pull ghcr.io/nazaro73/cloudnative-backend:$IMAGE_TAG
docker pull ghcr.io/nazaro73/cloudnative-frontend:$IMAGE_TAG

echo ""
echo "[3/4] Starting containers..."
export IMAGE_TAG=$IMAGE_TAG
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "[4/4] Running database migrations..."
sleep 10
docker exec backend npx prisma migrate deploy || echo "Warning: Migration may have failed or already applied"

echo ""
echo "========================================"
echo "  Deployment Complete!"
echo "========================================"
echo ""
echo "Services:"
echo "  - Frontend: http://localhost:8080"
echo "  - Backend:  http://localhost:3000"
echo "  - Database: localhost:5432"
echo ""
echo "Container Status:"
docker ps --filter "name=postgres" --filter "name=backend" --filter "name=frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
