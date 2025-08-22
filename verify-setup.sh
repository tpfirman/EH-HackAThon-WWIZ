#!/bin/bash

# WWIZ HTTPS Verification Script
# This script verifies that all components are correctly configured

echo "🔍 WWIZ HTTPS Configuration Verification"
echo "========================================"

# Check if required files exist
echo "📋 Checking required files..."

required_files=(
    "docker-compose.yml"
    "nginx/nginx.conf"
    ".env.template"
    "setup-https.sh"
    "renew-ssl.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check if scripts are executable
echo "🔧 Checking script permissions..."
for script in setup-https.sh renew-ssl.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script is executable"
    else
        echo "❌ $script is not executable"
        chmod +x "$script"
        echo "🔧 Fixed permissions for $script"
    fi
done

# Validate Docker Compose configuration
echo "🐳 Validating Docker Compose configuration..."
if docker compose config --quiet > /dev/null 2>&1; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration has errors"
    docker compose config
    exit 1
fi

# Check if .env file exists
echo "🔧 Environment configuration..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    source .env
    if [ -n "$DOMAIN_NAME" ] && [ -n "$SSL_EMAIL" ]; then
        echo "✅ Required environment variables are set"
    else
        echo "⚠️  Please configure DOMAIN_NAME and SSL_EMAIL in .env"
    fi
else
    echo "ℹ️  .env file not found - copy from .env.template"
fi

echo ""
echo "🎉 Configuration verification complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Configure .env file with your domain and email"
echo "   2. Ensure your domain points to this server"
echo "   3. Run ./setup-https.sh to deploy with HTTPS"
echo ""
echo "🔗 Your application will be available at: https://$DOMAIN_NAME"