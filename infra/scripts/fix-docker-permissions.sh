#!/bin/bash
# Quick fix for Docker permissions after group addition
# Run this script to resolve the Docker permission issue

echo "=== Docker Permission Fix ==="
echo "Current user: $(whoami)"
echo "Current groups: $(groups)"

# Check if user is in docker group
if groups | grep -q docker; then
    echo "✓ User is in docker group"
else
    echo "✗ User is NOT in docker group - adding now..."
    sudo usermod -a -G docker $(whoami)
    echo "✓ Added to docker group"
fi

# Check Docker socket permissions
echo "Docker socket permissions:"
ls -la /var/run/docker.sock

# Test Docker access with current session
echo "Testing Docker access..."
if docker ps &> /dev/null; then
    echo "✓ Docker access works - permissions are correct!"
    docker ps
else
    echo "✗ Docker access still denied"
    echo "This is expected - group membership requires session refresh"
    echo
    echo "=== SOLUTIONS ==="
    echo "1. Log out and log back in to refresh group membership"
    echo "2. Use 'newgrp docker' to start a new session with docker group"
    echo "3. Use 'sudo docker' commands until next login"
    echo "4. Run the containers as root (temporary fix):"
    echo "   sudo docker ps"
    echo "   sudo docker compose up -d"
    echo
    echo "=== TESTING WITH SUDO ==="
    echo "Docker version with sudo:"
    sudo docker --version
    echo "Current containers:"
    sudo docker ps
fi

echo
echo "=== RECOMMENDED NEXT STEPS ==="
echo "1. Either logout/login or run: newgrp docker"
echo "2. Then test: docker ps"
echo "3. Start containers: cd /home/ec2-user/anythingllm && docker compose up -d"
