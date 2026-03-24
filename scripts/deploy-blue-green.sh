#!/bin/bash
# Blue/Green Deployment Script
# This script deploys to the inactive color and switches the reverse proxy

set -e

IMAGE_TAG="${1:-latest}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================"
echo "  Blue/Green Deployment"
echo "  Image Tag: $IMAGE_TAG"
echo "========================================"

# Step 1: Read current active color
echo ""
echo "[1/6] Reading current active color..."
ACTIVE_COLOR_FILE="$PROJECT_ROOT/nginx/active-color.conf"
CURRENT_COLOR="blue"

if [ -f "$ACTIVE_COLOR_FILE" ]; then
    CURRENT_COLOR=$(grep -oP '(?<=set \$active_color )\w+' "$ACTIVE_COLOR_FILE" || echo "blue")
fi

echo "Current active color: $CURRENT_COLOR"

# Step 2: Determine target color
echo ""
echo "[2/6] Determining target color..."
if [ "$CURRENT_COLOR" = "blue" ]; then
    TARGET_COLOR="green"
else
    TARGET_COLOR="blue"
fi

echo "Target color: $TARGET_COLOR"

# Step 3: Pull new images
echo ""
echo "[3/6] Pulling new images..."
docker pull ghcr.io/nazaro73/cloudnative-backend:$IMAGE_TAG
docker pull ghcr.io/nazaro73/cloudnative-frontend:$IMAGE_TAG

# Step 4: Deploy to target color
echo ""
echo "[4/6] Deploying to $TARGET_COLOR..."
export IMAGE_TAG=$IMAGE_TAG

# Ensure base infrastructure is running
docker compose -f docker-compose.base.yml up -d

# Deploy target color
docker compose -f docker-compose.base.yml -f "docker-compose.$TARGET_COLOR.yml" up -d

# Step 5: Wait for services to be healthy
echo ""
echo "[5/6] Waiting for services to be healthy..."
sleep 15

# Run migrations
BACKEND_CONTAINER="backend-$TARGET_COLOR"
echo "Running migrations on $BACKEND_CONTAINER..."
docker exec $BACKEND_CONTAINER npx prisma migrate deploy || echo "Warning: Migration may have failed or already applied"

# Health check
MAX_RETRIES=10
RETRY=0
HEALTHY=false

while [ "$HEALTHY" = false ] && [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s -f "http://localhost:3000/health" > /dev/null 2>&1; then
        HEALTHY=true
        echo "Health check passed!"
    else
        RETRY=$((RETRY + 1))
        echo "Health check attempt $RETRY/$MAX_RETRIES..."
        sleep 3
    fi
done

if [ "$HEALTHY" = false ]; then
    echo "ERROR: New deployment is not healthy. Aborting switch."
    echo "Rollback: The previous version ($CURRENT_COLOR) is still active."
    exit 1
fi

# Step 6: Switch the proxy
echo ""
echo "[6/6] Switching reverse proxy to $TARGET_COLOR..."
echo "set \$active_color $TARGET_COLOR;" > "$ACTIVE_COLOR_FILE"

# Reload nginx
docker exec reverse-proxy nginx -s reload || echo "Warning: Nginx reload may have failed"

echo ""
echo "========================================"
echo "  Deployment Complete!"
echo "  Active color: $TARGET_COLOR"
echo "========================================"

echo ""
echo "Services:"
echo "  - Application: http://localhost"
echo "  - Status: http://localhost/status"

echo ""
echo "To rollback, run:"
echo "  ./scripts/switch-color.sh $CURRENT_COLOR"

echo ""
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "postgres|backend|frontend|reverse-proxy"
