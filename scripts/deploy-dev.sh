#!/bin/bash

# ====================================
# DEVELOPMENT DEPLOYMENT SCRIPT
# ====================================

set -e  # Exit on any error

# Configuration
IMAGE_TAG=$1
ENVIRONMENT="development"
APP_NAME="yourapp"
DEV_COMPOSE_FILE="docker-compose.dev.yml"

echo "🚀 Starting deployment to Development Environment"
echo "📦 Image Tag: $IMAGE_TAG"
echo "🌍 Environment: $ENVIRONMENT"

# ====================================
# VALIDATION
# ====================================

if [ -z "$IMAGE_TAG" ]; then
    echo "❌ Error: Image tag not provided"
    echo "Usage: $0 <image-tag>"
    exit 1
fi

if [ -z "$DEV_SERVER_HOST" ]; then
    echo "❌ Error: DEV_SERVER_HOST environment variable not set"
    exit 1
fi

# ====================================
# PRE-DEPLOYMENT CHECKS
# ====================================

echo "🔍 Running pre-deployment checks..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running or not accessible"
    exit 1
fi

# Check if required files exist
if [ ! -f "$DEV_COMPOSE_FILE" ]; then
    echo "❌ Docker Compose file not found: $DEV_COMPOSE_FILE"
    exit 1
fi

echo "✅ Pre-deployment checks passed"

# ====================================
# BACKUP CURRENT DEPLOYMENT
# ====================================

echo "💾 Creating backup of current deployment..."

# Create backup directory with timestamp
BACKUP_DIR="backups/dev-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current Docker Compose configuration
if [ -f "$DEV_COMPOSE_FILE" ]; then
    cp "$DEV_COMPOSE_FILE" "$BACKUP_DIR/"
fi

# Export current container state
docker-compose -f "$DEV_COMPOSE_FILE" ps > "$BACKUP_DIR/container-state.txt" 2>/dev/null || true

echo "✅ Backup created in $BACKUP_DIR"

# ====================================
# UPDATE CONFIGURATION
# ====================================

echo "⚙️ Updating configuration..."

# Update image tag in Docker Compose file
sed -i.bak "s|image: .*$APP_NAME.*|image: $IMAGE_TAG|g" "$DEV_COMPOSE_FILE"

# Update environment variables
export IMAGE_TAG="$IMAGE_TAG"
export ENVIRONMENT="$ENVIRONMENT"
export NODE_ENV="development"
export LOG_LEVEL="debug"

echo "✅ Configuration updated"

# ====================================
# DEPLOYMENT
# ====================================

echo "🚀 Deploying to Development..."

# Pull the latest image
echo "📥 Pulling Docker image..."
docker pull "$IMAGE_TAG"

# Stop existing containers gracefully
echo "⏹️ Stopping existing containers..."
docker-compose -f "$DEV_COMPOSE_FILE" down --timeout 30 || true

# Remove old containers and volumes (dev only)
echo "🧹 Cleaning up old resources..."
docker-compose -f "$DEV_COMPOSE_FILE" rm -f || true
docker volume prune -f || true

# Start new deployment
echo "🚀 Starting new deployment..."
docker-compose -f "$DEV_COMPOSE_FILE" up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 15

# ====================================
# POST-DEPLOYMENT VERIFICATION
# ====================================

echo "🔍 Running post-deployment verification..."

# Check container status
echo "📊 Container Status:"
docker-compose -f "$DEV_COMPOSE_FILE" ps

# Check logs for errors
echo "📋 Checking container logs..."
docker-compose -f "$DEV_COMPOSE_FILE" logs --tail=50 | grep -i error || echo "No errors found in logs"

# Verify services are responding
echo "🏥 Health check..."
HEALTH_CHECK_URL="http://localhost:3000/health"

for i in {1..10}; do
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        echo "✅ Application is healthy"
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ Health check failed after 10 attempts"
        echo "🚨 Rolling back..."
        
        # Rollback
        docker-compose -f "$DEV_COMPOSE_FILE" down
        if [ -f "$DEV_COMPOSE_FILE.bak" ]; then
            mv "$DEV_COMPOSE_FILE.bak" "$DEV_COMPOSE_FILE"
            docker-compose -f "$DEV_COMPOSE_FILE" up -d
        fi
        
        exit 1
    fi
    
    echo "⏳ Attempt $i/10: Waiting for application to be ready..."
    sleep 10
done

# ====================================
# CLEANUP
# ====================================

echo "🧹 Cleaning up..."

# Remove backup file
rm -f "$DEV_COMPOSE_FILE.bak"

# Clean up old Docker images (keep last 3)
echo "🗑️ Cleaning up old Docker images..."
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.ID}}" | \
grep "$APP_NAME" | \
tail -n +4 | \
awk '{print $4}' | \
xargs -r docker rmi || true

# ====================================
# SUCCESS NOTIFICATION
# ====================================

echo ""
echo "✅ Development deployment completed successfully!"
echo "🌍 Environment: $ENVIRONMENT"  
echo "📦 Image: $IMAGE_TAG"
echo "🔗 URL: http://dev.yourapp.com"
echo "📋 Logs: docker-compose -f $DEV_COMPOSE_FILE logs -f"
echo ""

# Log deployment to file
echo "$(date): Deployed $IMAGE_TAG to $ENVIRONMENT" >> deployment-history.log

exit 0