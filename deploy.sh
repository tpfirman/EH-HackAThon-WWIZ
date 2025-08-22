#!/bin/bash

# WWIZ Quick Deploy Script
# This script provides a simple way to deploy WWIZ with HTTPS

set -e

echo "🚀 WWIZ Quick Deploy with HTTPS"
echo "================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    echo "   Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed or not in PATH"
    echo "   Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Validate configuration
echo "🔧 Validating configuration..."
if docker-compose config --quiet; then
    echo "✅ Docker Compose configuration is valid"
else
    echo "❌ Docker Compose configuration is invalid"
    exit 1
fi

# Ask user for deployment type
echo ""
echo "Choose deployment type:"
echo "1) Development (self-signed certificate, local testing)"
echo "2) Production (Let's Encrypt certificate, requires domain)"
echo ""
read -p "Enter choice (1 or 2): " DEPLOY_TYPE

case $DEPLOY_TYPE in
    1)
        echo "🧪 Setting up development environment..."
        ./setup-https.sh
        ;;
    2)
        echo "🌐 Setting up production environment..."
        read -p "Enter your domain name: " DOMAIN
        read -p "Enter your email address: " EMAIL
        
        if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
            echo "❌ Domain and email are required for production setup"
            exit 1
        fi
        
        export DOMAIN EMAIL
        echo "📋 Using domain: $DOMAIN"
        echo "📋 Using email: $EMAIL"
        
        # First start with self-signed cert, then get real cert
        ./setup-https.sh
        sleep 10  # Wait for services to start
        ./scripts/get-letsencrypt-cert.sh
        ;;
    *)
        echo "❌ Invalid choice. Please run again and choose 1 or 2."
        exit 1
        ;;
esac

echo ""
echo "🎉 Deployment complete!"
echo ""
echo "Run health check: ./scripts/health-check.sh"
echo "View logs: docker-compose logs -f"
echo "Stop services: docker-compose down"