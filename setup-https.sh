#!/bin/bash

# WWIZ HTTPS Setup Script
# This script sets up SSL certificates and configures HTTPS for the WWIZ frontend

set -e

# Configuration
DOMAIN=${DOMAIN:-"wwiz.local"}
EMAIL=${EMAIL:-"admin@example.com"}
STAGING=${STAGING:-0}

echo "🔐 Setting up HTTPS for WWIZ frontend..."
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Check if domain is provided
if [ "$DOMAIN" = "wwiz.local" ]; then
    echo "⚠️  Using default domain 'wwiz.local'. For production, set DOMAIN environment variable."
fi

# Create directories
mkdir -p nginx/certs/live/$DOMAIN
mkdir -p nginx/www

# Generate self-signed certificate for initial setup (for development/testing)
if [ ! -f "nginx/certs/live/$DOMAIN/fullchain.pem" ]; then
    echo "🔧 Generating self-signed certificate for initial setup..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/certs/live/$DOMAIN/privkey.pem \
        -out nginx/certs/live/$DOMAIN/fullchain.pem \
        -subj "/C=AU/ST=Victoria/L=Melbourne/O=WWIZ/CN=$DOMAIN"
    
    # Create chain.pem (same as fullchain.pem for self-signed)
    cp nginx/certs/live/$DOMAIN/fullchain.pem nginx/certs/live/$DOMAIN/chain.pem
    
    echo "✅ Self-signed certificate generated for $DOMAIN"
    echo "⚠️  This is suitable for development only. For production, use get-letsencrypt-cert.sh"
fi

# Start the services
echo "🚀 Starting WWIZ with HTTPS support..."
docker-compose up -d

echo "✅ WWIZ is now running with HTTPS!"
echo ""
echo "📍 Access your application at:"
echo "   HTTP:  http://$DOMAIN (redirects to HTTPS)"
echo "   HTTPS: https://$DOMAIN"
echo ""
echo "🔧 Next steps for production:"
echo "   1. Set your domain: export DOMAIN=your-domain.com"
echo "   2. Get real SSL certificate: ./scripts/get-letsencrypt-cert.sh"
echo "   3. Update DNS to point to your server"
echo ""
echo "📋 To view logs: docker-compose logs -f"
echo "🛑 To stop: docker-compose down"