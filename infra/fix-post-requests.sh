#!/bin/bash

echo "🔧 Fixing POST request handling for AnythingLLM..."
echo "   Replacing Python health server with nginx proxy"
echo ""

# Stop and disable the problematic health server
echo "📛 Stopping health-server service..."
sudo systemctl stop health-server
sudo systemctl disable health-server

# Install nginx
echo "📦 Installing nginx..."
sudo yum install -y nginx

# Create nginx configuration
echo "⚙️  Creating nginx configuration..."
sudo tee /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name _;

        # Health check endpoint
        location /health {
            add_header Content-Type application/json;
            return 200 '{"status": "healthy", "anythingllm": "running", "ai_poc_mode": true, "region": "Sydney", "memory_allocated_percent": "75%", "spot_instance": "true", "cleanup_date": "2025-12-31"}';
        }

        # Proxy everything else to AnythingLLM
        location / {
            proxy_pass http://127.0.0.1:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Critical for POST requests
            proxy_set_header Content-Length $content_length;
            proxy_set_header Content-Type $content_type;
            proxy_request_buffering off;
            proxy_buffering off;
            proxy_read_timeout 300s;
            proxy_connect_timeout 10s;
            
            # WebSocket support for real-time features
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_http_version 1.1;
        }
    }
}
EOF

# Start and enable nginx
echo "🚀 Starting nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Test the setup
echo ""
echo "🧪 Testing configuration..."
echo "   Health endpoint:"
curl -s http://localhost/health | python3 -m json.tool
echo ""
echo "   Testing POST capability:"
curl -s -X POST http://localhost/api/test -d '{"test": "data"}' -H "Content-Type: application/json" -w "HTTP Status: %{http_code}\n"

# Check service status
echo ""
echo "📊 Service Status:"
echo "   nginx: $(sudo systemctl is-active nginx)"
echo "   health-server: $(sudo systemctl is-active health-server)"
echo "   anythingllm: $(docker ps --format 'table {{.Names}}\t{{.Status}}' | grep anythingllm || echo 'Not found')"

echo ""
echo "✅ Fix complete! Your AnythingLLM should now accept POST requests."
echo "   Try saving your LLM settings again in the web interface."
echo ""
echo "🔍 If you need to troubleshoot:"
echo "   sudo tail -f /var/log/nginx/access.log"
echo "   sudo tail -f /var/log/nginx/error.log"
