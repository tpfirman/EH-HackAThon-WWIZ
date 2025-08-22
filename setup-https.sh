#!/bin/bash

# WWIZ HTTPS Setup Script
# This script helps you deploy WWIZ with HTTPS support

set -e

echo "🔒 WWIZ HTTPS Setup Script"
echo "=========================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Please copy .env.template to .env and configure your settings."
    echo "   cp .env.template .env"
    echo "   nano .env"
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$DOMAIN_NAME" ] || [ -z "$SSL_EMAIL" ]; then
    echo "❌ Please configure DOMAIN_NAME and SSL_EMAIL in your .env file"
    exit 1
fi

echo "🌐 Domain: $DOMAIN_NAME"
echo "📧 Email: $SSL_EMAIL"

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p certbot/conf certbot/www nginx/ssl

# Replace placeholders in nginx.conf
echo "🔧 Configuring nginx..."
sed -e "s/server_name _;/server_name $DOMAIN_NAME www.$DOMAIN_NAME;/g" \
    -e "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" \
    nginx/nginx.conf > nginx/nginx.conf.tmp
mv nginx/nginx.conf.tmp nginx/nginx.conf

# Start nginx and certbot for initial certificate generation
echo "🚀 Starting services for SSL certificate generation..."
docker-compose up -d nginx

# Wait for nginx to be ready
echo "⏳ Waiting for nginx to be ready..."
sleep 10

# Generate SSL certificate
echo "🔐 Generating SSL certificate with Let's Encrypt..."
docker-compose run --rm certbot

# Restart nginx with SSL
echo "🔄 Restarting nginx with SSL configuration..."
docker-compose restart nginx

# Start all services
echo "🎉 Starting all WWIZ services..."
docker-compose up -d

echo ""
echo "✅ WWIZ is now running with HTTPS!"
echo "🌐 Access your application at: https://$DOMAIN_NAME"
echo ""
echo "📋 Next steps:"
echo "   - Configure your DNS to point $DOMAIN_NAME to this server"
echo "   - Set up automatic certificate renewal (see README.md)"
echo "   - Configure AnythingLLM through the web interface"
echo ""
echo "📊 Check status with: docker-compose ps"
echo "📜 View logs with: docker-compose logs -f"