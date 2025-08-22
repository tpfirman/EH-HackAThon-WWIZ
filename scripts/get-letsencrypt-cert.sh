#!/bin/bash

# Let's Encrypt SSL Certificate Setup for WWIZ
# This script obtains a real SSL certificate from Let's Encrypt

set -e

# Configuration
DOMAIN=${DOMAIN:-""}
EMAIL=${EMAIL:-""}
STAGING=${STAGING:-0}

if [ -z "$DOMAIN" ]; then
    echo "❌ Error: DOMAIN environment variable is required"
    echo "Usage: DOMAIN=your-domain.com EMAIL=your-email@example.com ./scripts/get-letsencrypt-cert.sh"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "❌ Error: EMAIL environment variable is required"
    echo "Usage: DOMAIN=your-domain.com EMAIL=your-email@example.com ./scripts/get-letsencrypt-cert.sh"
    exit 1
fi

echo "🔐 Obtaining Let's Encrypt SSL certificate..."
echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Determine if using staging or production
if [ "$STAGING" = "1" ]; then
    STAGING_ARG="--staging"
    echo "🧪 Using Let's Encrypt staging environment"
else
    STAGING_ARG=""
    echo "🌐 Using Let's Encrypt production environment"
fi

# Ensure nginx is running for HTTP-01 challenge
docker-compose up -d nginx

# Wait a moment for nginx to start
sleep 5

# Obtain certificate
echo "📋 Requesting certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    $STAGING_ARG \
    -d $DOMAIN

# Update nginx configuration with the new domain
echo "🔧 Updating nginx configuration..."
sed -i "s/wwiz\.local/$DOMAIN/g" nginx/nginx.conf

# Restart nginx to use the new certificate
echo "🔄 Restarting nginx with new certificate..."
docker-compose restart nginx

echo "✅ SSL certificate successfully obtained and configured!"
echo ""
echo "📍 Your WWIZ application is now available at:"
echo "   https://$DOMAIN"
echo ""
echo "🔄 Certificate will auto-renew via the certbot container"
echo "📋 To check certificate: openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"