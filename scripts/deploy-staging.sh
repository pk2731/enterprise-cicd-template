#!/bin/bash

# ====================================
# STAGING DEPLOYMENT SCRIPT
# ====================================

set -e  # Exit on any error

# Configuration
IMAGE_TAG=$1
ENVIRONMENT="staging"
APP_NAME="yourapp"
STAGING_COMPOSE_FILE="docker-compose.staging.yml"

echo "🚀 Starting deployment to Staging Environment"
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

if [ -z "$STAGING_SERVER_HOST" ]; then
    echo "❌ Error: STAGING_SERVER_HOST environment variable not set"
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
if [ ! -f "$STAGING_COMPOSE_FILE" ]; then
    echo "❌ Docker Compose file not found: $STAGING_COMPOSE_FILE"
    exit 1
fi

# Check if staging database is accessible
echo "🗃️ Checking database connectivity..."
if ! timeout 10 nc -z $STAGING_DB_HOST $STAGING_DB_PORT 2>/dev/null; then
    echo "❌ Cannot connect to staging database"
    exit 1
fi

echo "✅ Pre-deployment checks passed"

# ====================================
# BACKUP CURRENT DEPLOYMENT
# ====================================

echo "💾 Creating backup of current deployment..."

# Create backup directory with timestamp
BACKUP_DIR="backups/staging-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup current Docker Compose configuration
if [ -f "$STAGING_COMPOSE_FILE" ]; then
    cp "$STAGING_COMPOSE_FILE" "$BACKUP_DIR/"
fi

# Export current container state
docker-compose -f "$STAGING_COMPOSE_FILE" ps > "$BACKUP_DIR/container-state.txt" 2>/dev/null || true

echo "✅ Backup created in $BACKUP_DIR"

# ====================================
# BLUE-GREEN DEPLOYMENT PREPARATION
# ====================================

echo "🔄 Preparing blue-green deployment..."

# Update image tag in Docker Compose file
sed -i.bak "s|image: .*$APP_NAME.*|image: $IMAGE_TAG|g" "$STAGING_COMPOSE_FILE"

# Update environment variables
export IMAGE_TAG="$IMAGE_TAG"
export ENVIRONMENT="$ENVIRONMENT"
export NODE_ENV="staging"
export LOG_LEVEL="info"

echo "✅ Configuration updated"

# ====================================
# DATABASE MIGRATIONS
# ====================================

echo "🗃️ Running database migrations..."

# Pull the new image first
docker pull "$IMAGE_TAG"

# Run database migrations with the new image
docker run --rm \
    --network staging_network \
    -e DATABASE_URL="$STAGING_DATABASE_URL" \
    -e NODE_ENV="staging" \
    "$IMAGE_TAG" \
    npm run migrate

echo "✅ Database migrations completed"

# ====================================
# DEPLOYMENT
# ====================================

echo "🚀 Deploying to Staging..."

# Start new containers with new image (blue-green approach)
echo "🔵 Starting new containers..."
docker-compose -f "$STAGING_COMPOSE_FILE" up -d --no-deps --scale app=2 app

# Wait for new containers to be ready
echo "⏳ Waiting for new containers to start..."
sleep 30

# Health check for new containers
echo "🏥 Health checking new deployment..."
NEW_CONTAINER_ID=$(docker-compose -f "$STAGING_COMPOSE_FILE" ps -q app | head -1)

for i in {1..20}; do
    if docker exec "$NEW_CONTAINER_ID" curl -f -s http://localhost:3000/health > /dev/null; then
        echo "✅ New deployment is healthy"
        break
    fi
    
    if [ $i -eq 20 ]; then
        echo "❌ New deployment health check failed"
        echo "🚨 Rolling back..."
        
        # Stop new containers
        docker stop "$NEW_CONTAINER_ID"
        docker-compose -f "$STAGING_COMPOSE_FILE" up -d --scale app=1
        
        exit 1
    fi
    
    echo "⏳ Attempt $i/20: Waiting for new deployment to be ready..."
    sleep 10
done

# ====================================
# TRAFFIC SWITCHING
# ====================================

echo "🔄 Switching traffic to new deployment..."

# Update load balancer / reverse proxy configuration
# This would typically involve updating nginx config or API Gateway
docker-compose -f "$STAGING_COMPOSE_FILE" exec nginx nginx -s reload

# Wait for traffic to switch
sleep 10

# Stop old containers
echo "⏹️ Stopping old containers..."
OLD_CONTAINERS=$(docker-compose -f "$STAGING_COMPOSE_FILE" ps -q app | tail -n +2)
if [ ! -z "$OLD_CONTAINERS" ]; then
    docker stop $OLD_CONTAINERS
fi

# Clean up old containers
docker-compose -f "$STAGING_COMPOSE_FILE" up -d --scale app=1

# ====================================
# POST-DEPLOYMENT VERIFICATION
# ====================================

echo "🔍 Running post-deployment verification..."

# Check container status
echo "📊 Container Status:"
docker-compose -f "$STAGING_COMPOSE_FILE" ps

# Check application logs for errors
echo "📋 Checking application logs..."
docker-compose -f "$STAGING_COMPOSE_FILE" logs --tail=100 app | grep -i error || echo "No errors found in application logs"

# Verify external services connectivity
echo "🔗 Testing external service connections..."

# Test database connection
if docker-compose -f "$STAGING_COMPOSE_FILE" exec app npm run db:check; then
    echo "✅ Database connection successful"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Test Redis connection (if applicable)
if docker-compose -f "$STAGING_COMPOSE_FILE" exec app npm run redis:check; then
    echo "✅ Redis connection successful"
else
    echo "⚠️ Redis connection failed (non-critical)"
fi

# Final health check
echo "🏥 Final health check..."
HEALTH_CHECK_URL="https://staging.yourapp.com/health"

for i in {1..5}; do
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        echo "✅ Application is healthy and accessible"
        break
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ Final health check failed"
        exit 1
    fi
    
    echo "⏳ Attempt $i/5: Waiting for application to be accessible..."
    sleep 15
done

# ====================================
# PERFORMANCE VALIDATION
# ====================================

echo "⚡ Running performance validation..."

# Basic load test
echo "🏋️ Running basic load test..."
if command -v ab &> /dev/null; then
    ab -n 100 -c 10 "$HEALTH_CHECK_URL" > /tmp/loadtest.txt
    
    # Check if response time is acceptable
    AVG_TIME=$(grep "Time per request" /tmp/loadtest.txt | head -1 | awk '{print $4}')
    if (( $(echo "$AVG_TIME < 500" | bc -l) )); then
        echo "✅ Performance test passed (avg: ${AVG_TIME}ms)"
    else
        echo "⚠️ Performance test warning: High response time (avg: ${AVG_TIME}ms)"
    fi
else
    echo "⏭️ Skipping load test (ab not available)"
fi

# ====================================
# CLEANUP
# ====================================

echo "🧹 Cleaning up..."

# Remove backup configuration file
rm -f "$STAGING_COMPOSE_FILE.bak"

# Clean up old Docker images (keep last 5 for staging)
echo "🗑️ Cleaning up old Docker images..."
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.ID}}" | \
grep "$APP_NAME" | \
tail -n +6 | \
awk '{print $4}' | \
xargs -r docker rmi || true

# Clean up stopped containers
docker container prune -f || true

# ====================================
# SUCCESS NOTIFICATION
# ====================================

echo ""
echo "✅ Staging deployment completed successfully!"
echo "🌍 Environment: $ENVIRONMENT"
echo "📦 Image: $IMAGE_TAG"
echo "🔗 URL: https://staging.yourapp.com"
echo "📋 Logs: docker-compose -f $STAGING_COMPOSE_FILE logs -f"
echo "💾 Backup: $BACKUP_DIR"
echo ""

# Log deployment to file
echo "$(date): Deployed $IMAGE_TAG to $ENVIRONMENT" >> deployment-history.log

# Send notification to monitoring system
curl -X POST "$MONITORING_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Staging deployment successful\", \"environment\": \"$ENVIRONMENT\", \"image\": \"$IMAGE_TAG\"}" || true

exit 0