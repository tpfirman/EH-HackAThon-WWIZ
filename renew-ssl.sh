#!/bin/bash

# SSL Certificate Renewal Script for WWIZ
# Add this to crontab to run automatically: 0 12 * * * /path/to/renew-ssl.sh

echo "🔄 Renewing SSL certificates..."

# Navigate to the WWIZ directory
cd "$(dirname "$0")"

# Attempt to renew certificates
docker-compose run --rm certbot renew

# Reload nginx if certificates were renewed
if [ $? -eq 0 ]; then
    echo "✅ Certificates renewed successfully"
    docker-compose exec nginx nginx -s reload
    echo "🔄 Nginx reloaded"
else
    echo "ℹ️ No certificates needed renewal"
fi

echo "✅ SSL renewal check complete"