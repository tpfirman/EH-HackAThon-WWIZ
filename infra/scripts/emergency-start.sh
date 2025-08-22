#!/bin/bash
# Simple immediate fix script - no complex heredocs or permission checks
# Just get AnythingLLM running with sudo

echo "=== Emergency AnythingLLM Startup ==="
echo "Bypassing permission checks and starting containers with sudo"

# Navigate to correct directory
if [ -d "/home/ec2-user/anythingllm" ]; then
    cd /home/ec2-user/anythingllm
    echo "✓ In AnythingLLM directory"
else
    echo "✗ AnythingLLM directory not found, creating it..."
    mkdir -p /home/ec2-user/anythingllm
    cd /home/ec2-user/anythingllm
fi

# Check for docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo "Creating minimal docker-compose.yml for AnythingLLM..."
    cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'
services:
  anythingllm:
    container_name: anythingllm
    image: mintplexlabs/anythingllm:latest
    ports:
      - "3001:3001"
    volumes:
      - anythingllm_storage:/app/server/storage
      - anythingllm_logs:/app/server/logs/
    environment:
      - NODE_ENV=production
      - DISABLE_TELEMETRY=true
    restart: unless-stopped
volumes:
  anythingllm_storage:
  anythingllm_logs:
COMPOSE_EOF
    echo "✓ Created docker-compose.yml"
fi

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user/anythingllm

echo "Starting containers with sudo..."

# Try docker compose v2 first
if docker compose version &> /dev/null; then
    echo "Using Docker Compose v2..."
    docker compose up -d
elif command -v docker-compose &> /dev/null; then
    echo "Using Docker Compose v1..."
    docker-compose up -d
else
    echo "No docker compose found, trying direct docker run..."
    docker run -d --name anythingllm \
        -p 3001:3001 \
        -v anythingllm_storage:/app/server/storage \
        -v anythingllm_logs:/app/server/logs \
        -e NODE_ENV=production \
        -e DISABLE_TELEMETRY=true \
        --restart unless-stopped \
        mintplexlabs/anythingllm:latest
fi

echo
echo "Checking container status..."
sleep 3
docker ps --filter "name=anythingllm"

echo
echo "Testing AnythingLLM accessibility..."
if curl -s http://localhost:3001 > /dev/null; then
    echo "✓ AnythingLLM is responding on port 3001"
else
    echo "⏳ AnythingLLM may still be starting up..."
    echo "Check logs: docker logs anythingllm"
fi

echo
echo "=== Next Steps ==="
echo "1. Check nginx status: systemctl status nginx"
echo "2. Test public access via your instance's public IP"
echo "3. Check logs if needed: docker logs anythingllm"
