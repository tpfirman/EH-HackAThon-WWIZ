#!/bin/bash
# Manual AnythingLLM startup script
# Run this to start AnythingLLM containers when Docker permissions are an issue

echo "=== Manual AnythingLLM Startup ==="
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"

# Navigate to AnythingLLM directory
if [ -d "/home/ec2-user/anythingllm" ]; then
    cd /home/ec2-user/anythingllm
    echo "✓ Found AnythingLLM directory"
else
    echo "✗ AnythingLLM directory not found at /home/ec2-user/anythingllm"
    echo "Looking for docker-compose.yml files..."
    find /home/ec2-user -name "docker-compose.yml" -o -name "compose.yml" 2>/dev/null
    exit 1
fi

# Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ] || [ -f "compose.yml" ]; then
    echo "✓ Found Docker Compose file"
    ls -la *.yml 2>/dev/null || ls -la compose.yml 2>/dev/null
else
    echo "✗ No Docker Compose file found"
    ls -la
    exit 1
fi

echo
echo "=== Starting AnythingLLM Containers ==="

# Method 1: Try as ec2-user with newgrp
echo "Method 1: Trying with group refresh..."
if sudo -u ec2-user bash -c 'newgrp docker <<EOF
cd /home/ec2-user/anythingllm
docker compose up -d
EOF' 2>/dev/null; then
    echo "✓ Started successfully with group refresh!"
else
    echo "✗ Group refresh method failed"
    
    # Method 2: Try with sudo
    echo "Method 2: Trying with sudo..."
    if sudo docker compose up -d; then
        echo "✓ Started successfully with sudo!"
    else
        echo "✗ Sudo method failed too"
        
        # Method 3: Try docker-compose v1
        echo "Method 3: Trying docker-compose v1..."
        if sudo docker-compose up -d; then
            echo "✓ Started successfully with docker-compose v1!"
        else
            echo "✗ All methods failed"
            echo "Check Docker installation and compose files"
            exit 1
        fi
    fi
fi

echo
echo "=== Verifying Containers ==="
sleep 3

# Check containers
echo "Running containers:"
if sudo docker ps --filter "name=anythingllm"; then
    echo "✓ Container check successful"
else
    echo "✗ No containers found or Docker access issue"
fi

echo
echo "=== Container Logs (last 10 lines) ==="
sudo docker logs anythingllm-anythingllm-1 --tail 10 2>/dev/null || echo "Could not retrieve logs"

echo
echo "=== Next Steps ==="
echo "1. Check if AnythingLLM is accessible: curl http://localhost:3001"
echo "2. Check nginx status: sudo systemctl status nginx"
echo "3. Access via web browser on the instance public IP"
echo "4. To fix permissions permanently: logout and login as ec2-user"
