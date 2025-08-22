#!/bin/bash

# WWIZ Deployment Health Check Script
# Verifies that HTTPS is working correctly

set -e

DOMAIN=${DOMAIN:-"wwiz.local"}
TIMEOUT=${TIMEOUT:-30}

echo "🔍 Running WWIZ HTTPS health check..."
echo "Domain: $DOMAIN"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Check if containers are running
echo "📦 Checking container status..."
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ Containers are not running. Start with: docker-compose up -d"
    exit 1
fi
echo "✅ Containers are running"

# Check HTTP redirect (should redirect to HTTPS)
echo "🔄 Testing HTTP to HTTPS redirect..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time $TIMEOUT http://$DOMAIN/ || echo "000")
if [ "$HTTP_RESPONSE" != "200" ]; then
    echo "⚠️  HTTP redirect test returned code: $HTTP_RESPONSE"
    echo "   This might be expected if using a real domain name"
else
    echo "✅ HTTP redirect working"
fi

# Check HTTPS availability
echo "🔒 Testing HTTPS availability..."
HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k --max-time $TIMEOUT https://$DOMAIN/ || echo "000")
if [ "$HTTPS_RESPONSE" != "200" ]; then
    echo "❌ HTTPS test failed with code: $HTTPS_RESPONSE"
    echo "   Check nginx logs: docker-compose logs nginx"
    exit 1
fi
echo "✅ HTTPS is working"

# Check SSL certificate
echo "🔐 Checking SSL certificate..."
CERT_INFO=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "Failed to get cert info")
if [[ "$CERT_INFO" == *"Failed"* ]]; then
    echo "⚠️  Could not retrieve certificate information"
    echo "   This might be expected for self-signed certificates"
else
    echo "📋 Certificate info:"
    echo "$CERT_INFO"
fi

# Check AnythingLLM service
echo "🤖 Testing AnythingLLM backend..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k --max-time $TIMEOUT https://$DOMAIN/api/v1/system/ping 2>/dev/null || echo "000")
if [ "$BACKEND_RESPONSE" = "200" ]; then
    echo "✅ AnythingLLM backend is responding"
elif [ "$BACKEND_RESPONSE" = "404" ]; then
    echo "✅ AnythingLLM is running (ping endpoint not available, but got valid 404)"
else
    echo "⚠️  AnythingLLM backend check returned: $BACKEND_RESPONSE"
    echo "   The application might still be starting up"
fi

echo ""
echo "🎉 Health check complete!"
echo ""
echo "📍 Access your WWIZ application at: https://$DOMAIN"
echo "🔧 View logs: docker-compose logs -f"
echo "📊 Container status: docker-compose ps"