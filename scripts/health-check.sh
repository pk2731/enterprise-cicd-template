#!/bin/bash

# ====================================
# UNIVERSAL HEALTH CHECK SCRIPT
# ====================================

set -e

# Configuration
BASE_URL=$1
TIMEOUT=${2:-30}
MAX_RETRIES=${3:-10}
RETRY_DELAY=${4:-5}

echo "🏥 Starting comprehensive health check"
echo "🌐 URL: $BASE_URL"
echo "⏱️ Timeout: ${TIMEOUT}s"
echo "🔄 Max Retries: $MAX_RETRIES"

# ====================================
# VALIDATION
# ====================================

if [ -z "$BASE_URL" ]; then
    echo "❌ Error: Base URL not provided"
    echo "Usage: $0 <base-url> [timeout] [max-retries] [retry-delay]"
    exit 1
fi

# ====================================
# HEALTH CHECK ENDPOINTS
# ====================================

HEALTH_ENDPOINTS=(
    "$BASE_URL/health"
    "$BASE_URL/api/health"
    "$BASE_URL/status"
    "$BASE_URL/ping"
)

# ====================================
# BASIC CONNECTIVITY CHECK
# ====================================

echo "🔌 Testing basic connectivity..."

for retry in $(seq 1 $MAX_RETRIES); do
    echo "🔄 Attempt $retry/$MAX_RETRIES"
    
    # Test basic connectivity
    if curl -f -s --max-time $TIMEOUT "$BASE_URL" > /dev/null 2>&1; then
        echo "✅ Basic connectivity successful"
        break
    fi
    
    if [ $retry -eq $MAX_RETRIES ]; then
        echo "❌ Basic connectivity failed after $MAX_RETRIES attempts"
        exit 1
    fi
    
    echo "⏳ Retrying in ${RETRY_DELAY}s..."
    sleep $RETRY_DELAY
done

# ====================================
# HEALTH ENDPOINT CHECKS
# ====================================

echo "🏥 Testing health endpoints..."

HEALTH_CHECK_PASSED=false

for endpoint in "${HEALTH_ENDPOINTS[@]}"; do
    echo "🔍 Testing: $endpoint"
    
    # Check if endpoint responds
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$endpoint" || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Health endpoint responded: $endpoint (HTTP $HTTP_CODE)"
        
        # Get detailed response
        RESPONSE=$(curl -s --max-time $TIMEOUT "$endpoint" || echo "{}")
        echo "📋 Response: $RESPONSE"
        
        # Parse JSON response if possible
        if command -v jq &> /dev/null; then
            STATUS=$(echo "$RESPONSE" | jq -r '.status // .health // "unknown"' 2>/dev/null || echo "unknown")
            if [ "$STATUS" = "ok" ] || [ "$STATUS" = "healthy" ] || [ "$STATUS" = "UP" ]; then
                echo "✅ Application status: $STATUS"
                HEALTH_CHECK_PASSED=true
                break
            else
                echo "⚠️ Application status: $STATUS"
            fi
        else
            HEALTH_CHECK_PASSED=true
            break
        fi
    else
        echo "⚠️ Health endpoint failed: $endpoint (HTTP $HTTP_CODE)"
    fi
done

if [ "$HEALTH_CHECK_PASSED" = false ]; then
    echo "❌ All health endpoints failed"
    exit 1
fi

# ====================================
# PERFORMANCE CHECKS
# ====================================

echo "⚡ Running performance checks..."

# Response time check
RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}" --max-time $TIMEOUT "$BASE_URL")
RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc)

echo "📊 Response time: ${RESPONSE_TIME_MS}ms"

# Response time validation
if (( $(echo "$RESPONSE_TIME_MS > 5000" | bc -l) )); then
    echo "⚠️ High response time detected (>${RESPONSE_TIME_MS}ms)"
    exit 1
elif (( $(echo "$RESPONSE_TIME_MS > 1000" | bc -l) )); then
    echo "⚠️ Moderate response time (${RESPONSE_TIME_MS}ms)"
else
    echo "✅ Good response time (${RESPONSE_TIME_MS}ms)"
fi

# ====================================
# API ENDPOINT CHECKS
# ====================================

echo "🔍 Testing critical API endpoints..."

API_ENDPOINTS=(
    "$BASE_URL/api/status"
    "$BASE_URL/api/version"
    "$BASE_URL/api/metrics"
)

for endpoint in "${API_ENDPOINTS[@]}"; do
    echo "🔍 Testing API: $endpoint"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$endpoint" || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ API endpoint OK: $endpoint"
    elif [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "🔒 API endpoint protected (expected): $endpoint"
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⏭️ API endpoint not found (optional): $endpoint"
    else
        echo "⚠️ API endpoint issue: $endpoint (HTTP $HTTP_CODE)"
    fi
done

# ====================================
# DATABASE CONNECTIVITY CHECK
# ====================================

echo "🗃️ Testing database connectivity..."

DB_HEALTH_ENDPOINT="$BASE_URL/api/db/health"
DB_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$DB_HEALTH_ENDPOINT" || echo "000")

if [ "$DB_HTTP_CODE" = "200" ]; then
    echo "✅ Database connectivity confirmed"
elif [ "$DB_HTTP_CODE" = "404" ]; then
    echo "⏭️ Database health endpoint not available"
else
    echo "⚠️ Database connectivity issue (HTTP $DB_HTTP_CODE)"
fi

# ====================================
# EXTERNAL DEPENDENCIES CHECK
# ====================================

echo "🔗 Testing external dependencies..."

DEPENDENCY_ENDPOINTS=(
    "$BASE_URL/api/dependencies/health"
    "$BASE_URL/api/external/status"
)

for endpoint in "${DEPENDENCY_ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$endpoint" || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Dependencies healthy"
        
        # Get detailed dependency status
        DEPS_RESPONSE=$(curl -s --max-time $TIMEOUT "$endpoint" || echo "{}")
        if command -v jq &> /dev/null; then
            echo "📋 Dependencies: $(echo "$DEPS_RESPONSE" | jq -c '.' 2>/dev/null || echo "$DEPS_RESPONSE")"
        fi
        break
    elif [ "$HTTP_CODE" = "404" ]; then
        echo "⏭️ Dependencies endpoint not available"
        break
    fi
done

# ====================================
# SECURITY HEADERS CHECK
# ====================================

echo "🔒 Checking security headers..."

HEADERS=$(curl -I -s --max-time $TIMEOUT "$BASE_URL" || echo "")

# Check for important security headers
SECURITY_HEADERS=(
    "Content-Security-Policy"
    "X-Frame-Options"
    "X-Content-Type-Options"
    "Strict-Transport-Security"
    "X-XSS-Protection"
)

for header in "${SECURITY_HEADERS[@]}"; do
    if echo "$HEADERS" | grep -i "$header:" > /dev/null; then
        echo "✅ Security header present: $header"
    else
        echo "⚠️ Security header missing: $header"
    fi
done

# ====================================
# LOAD TEST (BASIC)
# ====================================

if command -v ab &> /dev/null; then
    echo "🏋️ Running basic load test..."
    
    # Run a small load test (10 requests, 2 concurrent)
    ab -n 10 -c 2 -q "$BASE_URL" > /tmp/health_loadtest.txt 2>/dev/null || true
    
    if [ -f /tmp/health_loadtest.txt ]; then
        REQUESTS_PER_SEC=$(grep "Requests per second" /tmp/health_loadtest.txt | awk '{print $4}' || echo "0")
        FAILED_REQUESTS=$(grep "Failed requests" /tmp/health_loadtest.txt | awk '{print $3}' || echo "0")
        
        echo "📊 Load test results:"
        echo "   - Requests per second: $REQUESTS_PER_SEC"
        echo "   - Failed requests: $FAILED_REQUESTS"
        
        if [ "$FAILED_REQUESTS" = "0" ]; then
            echo "✅ Load test passed"
        else
            echo "⚠️ Load test had failures"
        fi
        
        rm -f /tmp/health_loadtest.txt
    fi
else
    echo "⏭️ Skipping load test (ab not available)"
fi

# ====================================
# FINAL VALIDATION
# ====================================

echo "🔍 Final validation..."

# One final check to ensure everything is still working
FINAL_CHECK=$(curl -f -s --max-time 10 "$BASE_URL/health" || curl -f -s --max-time 10 "$BASE_URL" || echo "FAIL")

if [ "$FINAL_CHECK" != "FAIL" ]; then
    echo "✅ Final validation passed"
else
    echo "❌ Final validation failed"
    exit 1
fi

# ====================================
# SUCCESS REPORT
# ====================================

echo ""
echo "🎉 Health check completed successfully!"
echo "🌐 URL: $BASE_URL"
echo "⏱️ Response time: ${RESPONSE_TIME_MS}ms"
echo "✅ All critical checks passed"
echo ""

# Return success
exit 0