#!/bin/bash
# Manual Docker installation script
# Run this if the main setup script fails to install Docker

echo "=== Manual Docker Installation ==="
echo "Date: $(date)"
echo "User: $(whoami)"

# Check if already installed
if command -v docker &> /dev/null; then
    echo "Docker is already installed:"
    docker --version
    echo "Checking service status..."
    systemctl status docker --no-pager
    exit 0
fi

echo "Docker not found, proceeding with installation..."

# Method 1: Try amazon-linux-extras
if command -v amazon-linux-extras &> /dev/null; then
    echo "Attempting installation via amazon-linux-extras..."
    if amazon-linux-extras install docker=latest -y; then
        echo "✓ Docker installed successfully via amazon-linux-extras"
    else
        echo "✗ Failed to install via amazon-linux-extras"
        echo "Trying method 2..."
    fi
fi

# Method 2: Try direct yum install
if ! command -v docker &> /dev/null; then
    echo "Attempting installation via yum..."
    if yum install -y docker; then
        echo "✓ Docker installed successfully via yum"
    else
        echo "✗ Failed to install via yum"
        echo "Trying method 3..."
    fi
fi

# Method 3: Try docker-ce repository
if ! command -v docker &> /dev/null; then
    echo "Attempting installation via Docker CE repository..."
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    if yum install -y docker-ce docker-ce-cli containerd.io; then
        echo "✓ Docker installed successfully via Docker CE repository"
    else
        echo "✗ All installation methods failed"
        exit 1
    fi
fi

# Verify installation
if command -v docker &> /dev/null; then
    echo "✓ Docker installation verified:"
    docker --version
    
    # Start and enable service
    echo "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
    
    echo "Adding ec2-user to docker group..."
    usermod -a -G docker ec2-user
    
    echo "Docker service status:"
    systemctl status docker --no-pager
    
    echo
    echo "✓ Docker installation complete!"
    echo "Note: You may need to log out and back in for group membership to take effect"
else
    echo "✗ Docker installation failed - command still not found"
    exit 1
fi
