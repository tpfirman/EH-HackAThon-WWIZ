#!/bin/bash
# AI POC Setup Script - External version to avoid CloudFormation UserData changes
# This script is pulled from GitHub to prevent instance replacement on updates
# IDEMPOTENT: Safe to re-run multiple times

set -e

# Create lock file to track setup progress
SETUP_LOCK="/var/log/ai-poc-setup.lock"
SETUP_LOG="/var/log/ai-poc-setup.log"

echo "=== AI POC Setup Starting ===" | tee -a "$SETUP_LOG"
echo "Timestamp: $(date)" | tee -a "$SETUP_LOG"
echo "Memory Percent: ${CF_MEMORY_PERCENT:-70}" | tee -a "$SETUP_LOG"
echo "Region: ${CF_REGION_NAME:-Sydney}" | tee -a "$SETUP_LOG"
echo "Spot Instance: ${CF_USE_SPOT:-true}" | tee -a "$SETUP_LOG"
echo "Stack: ${CF_STACK_NAME:-unknown}" | tee -a "$SETUP_LOG"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SETUP_LOG"
}

# Function to run docker compose with fallback
docker_compose() {
    if docker compose version &> /dev/null; then
        docker compose "$@"
    elif command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        log "ERROR: Neither 'docker compose' nor 'docker-compose' is available"
        return 1
    fi
}

# Check if already fully set up
if [ -f "$SETUP_LOCK" ] && [ "$(cat $SETUP_LOCK)" = "COMPLETE" ]; then
    log "Setup already completed. Checking services..."
    
    # Quick health check of services
    if systemctl is-active --quiet docker && systemctl is-active --quiet nginx; then
        if docker ps | grep -q anythingllm; then
            log "All services running. Setup verification complete."
            exit 0
        fi
    fi
    log "Services need restart. Continuing with setup..."
fi

echo "RUNNING" > "$SETUP_LOCK"

# Install essential packages including curl for health checks
log "Updating system packages..."
yum update -y 2>&1 | tee -a "$SETUP_LOG"
yum update -y amazon-linux-extras 2>&1 | tee -a "$SETUP_LOG"
amazon-linux-extras enable openssl11 2>&1 | tee -a "$SETUP_LOG"
yum clean metadata 2>&1 | tee -a "$SETUP_LOG"



log "Installing essential packages..."
yum install -y curl 2>&1 | tee -a "$SETUP_LOG"


# Install latest Docker from Amazon Linux Extras and enable
if ! command -v docker &> /dev/null; then
    log "Installing Docker..."
    amazon-linux-extras install docker=latest -y 2>&1 | tee -a "$SETUP_LOG"
else
    log "Docker already installed, skipping..."
fi

if ! systemctl is-active --quiet docker; then
    log "Starting Docker service..."
    systemctl start docker
    systemctl enable docker
fi

# Add ec2-user to docker group if not already added
if ! groups ec2-user | grep -q docker; then
    log "Adding ec2-user to docker group..."
    usermod -a -G docker ec2-user
fi

# Install Docker Compose v2 if not available
if ! docker compose version &> /dev/null; then
    log "Installing Docker Compose v2..."
    # Download Docker Compose v2
    DOCKER_COMPOSE_VERSION="v2.21.0"
    curl -fsSL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Create Docker CLI plugin directory and symlink
    mkdir -p /usr/local/lib/docker/cli-plugins
    ln -sf /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Also create it for ec2-user
    sudo -u ec2-user mkdir -p /home/ec2-user/.docker/cli-plugins
    ln -sf /usr/local/bin/docker-compose /home/ec2-user/.docker/cli-plugins/docker-compose
    
    log "Docker Compose v2 installed successfully"
else
    log "Docker Compose already available, skipping..."
fi

# Install traditional docker-compose as backup if neither method works
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    log "Installing traditional docker-compose as fallback..."
    # Install docker-compose via pip (more reliable on Amazon Linux 2)
    yum install -y python3-pip
    pip3 install docker-compose
    log "Traditional docker-compose installed via pip"
fi

# Install latest nginx from Amazon Linux Extras
if ! command -v nginx &> /dev/null; then
    log "Installing nginx..."
    amazon-linux-extras install nginx1=latest -y 2>&1 | tee -a "$SETUP_LOG"
else
    log "nginx already installed, skipping..."
fi

# Install latest OpenSSL 1.1 from Amazon Linux Extras (resolves urllib3 compatibility)
if ! rpm -q openssl1 &> /dev/null; then
    log "Installing OpenSSL 1.1..."
    amazon-linux-extras install openssl1 -y 2>&1 | tee -a "$SETUP_LOG"
    yum install -y openssl11 openssl11-devel 2>&1 | tee -a "$SETUP_LOG"
else
    log "OpenSSL 1.1 already installed, skipping..."
fi

# Verify installations and get versions
log "Logging installed versions..."
echo "=== Installed Versions ===" > /var/log/package-versions.log
docker --version >> /var/log/package-versions.log
docker_compose version >> /var/log/package-versions.log 2>&1 || echo "Docker Compose not available" >> /var/log/package-versions.log
nginx -v >> /var/log/package-versions.log 2>&1
openssl version >> /var/log/package-versions.log

# Ensure Docker is fully started before proceeding
sleep 10

# Calculate memory allocation based on percentage
TOTAL_MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEMORY_MB=$((TOTAL_MEMORY_KB / 1024))
ANYTHINGLLM_MEMORY_MB=$((TOTAL_MEMORY_MB * ${CF_MEMORY_PERCENT:-70} / 100))
ANYTHINGLLM_MEMORY_RESERVATION_MB=$((ANYTHINGLLM_MEMORY_MB * 60 / 100))

echo "Instance Memory: ${TOTAL_MEMORY_MB}MB, AnythingLLM Allocation: ${ANYTHINGLLM_MEMORY_MB}MB (${CF_MEMORY_PERCENT:-70}%)" > /var/log/memory-allocation.log

# Basic CloudWatch logging setup (minimal for POC)
if ! command -v awslogs &> /dev/null; then
    log "Installing CloudWatch logs agent..."
    yum install -y awslogs 2>&1 | tee -a "$SETUP_LOG"
else
    log "CloudWatch logs agent already installed, skipping..."
fi

if [ ! -f /etc/awslogs/awslogs.conf.backup ]; then
    log "Configuring CloudWatch logs..."
    cp /etc/awslogs/awslogs.conf /etc/awslogs/awslogs.conf.backup
cat << EOF > /etc/awslogs/awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/messages]
file = /var/log/messages
log_group_name = /ai-poc/${CF_STACK_NAME:-ai-poc}/system
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/anythingllm.log]
file = /home/ec2-user/anythingllm/logs/server.log
log_group_name = /ai-poc/${CF_STACK_NAME:-ai-poc}/anythingllm
log_stream_name = {instance_id}
datetime_format = %Y-%m-%d %H:%M:%S
EOF

# Set region for CloudWatch logs
log "Setting CloudWatch region configuration..."
sed -i "s/region = us-east-1/region = ${CF_AWS_REGION:-ap-southeast-2}/" /etc/awslogs/awscli.conf

if ! systemctl is-active --quiet awslogsd; then
    log "Starting CloudWatch logs service..."
    systemctl start awslogsd
    systemctl enable awslogsd
fi

# Create AnythingLLM setup script with dynamic memory allocation
log "Creating AnythingLLM setup script..."
mkdir -p /home/ec2-user/anythingllm/{logs,storage}

cat << 'EOF' > /home/ec2-user/setup-anythingllm.sh
#!/bin/bash

# Create docker-compose.yml for AnythingLLM with dynamic memory
mkdir -p /home/ec2-user/anythingllm/{logs,storage}
cd /home/ec2-user/anythingllm

# Stop existing container if running
if docker ps | grep -q anythingllm; then
    echo "Stopping existing AnythingLLM container..."
    docker stop anythingllm || true
    docker rm anythingllm || true
fi

# Convert comma-separated env vars to Docker format
ENV_VARS="${CF_ENV_VARS:-NODE_ENV=production,DISABLE_TELEMETRY=true}"
DOCKER_ENV=""
IFS=',' read -ra ADDR <<< "$ENV_VARS"
for i in "${ADDR[@]}"; do
  DOCKER_ENV="$DOCKER_ENV\n                - \"$i\""
done

cat << DOCKER_COMPOSE_EOF > docker-compose.yml
version: '3.8'
services:
  anythingllm:
    image: mintplexlabs/anythingllm:latest
    container_name: anythingllm
    ports:
      - "3001:3001"
    volumes:
      - ./storage:/app/server/storage
      - ./logs:/app/server/logs
    environment:$(echo -e "$DOCKER_ENV")
      - STORAGE_DIR=/app/server/storage
      - LOG_LEVEL=info
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: ${ANYTHINGLLM_MEMORY_MB}M
        reservations:
          memory: ${ANYTHINGLLM_MEMORY_RESERVATION_MB}M
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

volumes:
  anythingllm_storage:
  anythingllm_logs:
DOCKER_COMPOSE_EOF

# Set correct ownership
chown -R ec2-user:ec2-user /home/ec2-user/anythingllm

# Start AnythingLLM
if docker compose version &> /dev/null; then
    sudo -u ec2-user docker compose up -d
elif command -v docker-compose &> /dev/null; then
    sudo -u ec2-user docker-compose up -d
else
    echo "ERROR: Neither 'docker compose' nor 'docker-compose' is available"
    exit 1
fi

echo "AnythingLLM starting with ${ANYTHINGLLM_MEMORY_MB}MB memory allocation"
echo "AI POC setup complete! Available 24/7 for testing and evaluation."
echo "Region: ${CF_REGION_NAME:-Sydney} | Spot Instance: ${CF_USE_SPOT:-true}"
EOF

chmod +x /home/ec2-user/setup-anythingllm.sh

# Run the setup (with some delay to ensure Docker is ready)
log "Waiting for Docker to be fully ready..."
sleep 30

log "Starting AnythingLLM setup..."
/home/ec2-user/setup-anythingllm.sh 2>&1 | tee -a "$SETUP_LOG"

# Create nginx configuration for proxy and health checks
log "Configuring nginx proxy..."
if [ ! -f /etc/nginx/nginx.conf.backup ]; then
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
fi
cat << 'NGINXCONF' > /etc/nginx/nginx.conf
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
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;

        # Health check endpoint
        location /health {
            access_log off;
            return 200 '{"status":"healthy","anythingllm":"running","ai_poc_mode":true,"region":"Sydney","spot_instance":"true","cleanup_date":"2025-12-31"}';
            add_header Content-Type application/json;
        }

        # Proxy all other requests to AnythingLLM
        location / {
            proxy_pass http://localhost:3001;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Handle all HTTP methods including POST
            proxy_method $request_method;
            client_max_body_size 100M;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }
    }
}
NGINXCONF

# Set correct SELinux context for nginx (if SELinux is enabled)
setsebool -P httpd_can_network_connect 1 2>/dev/null || true

# Test nginx configuration before starting
log "Testing nginx configuration..."
nginx -t 2>&1 | tee -a "$SETUP_LOG"

# Start and enable nginx
log "Starting nginx service..."
systemctl enable nginx
systemctl start nginx

# Wait for AnythingLLM to be ready before finalizing
log "Waiting for AnythingLLM to be ready..."
for i in {1..30}; do
    if curl -f http://localhost:3001 >/dev/null 2>&1; then
        log "AnythingLLM is ready!"
        break
    fi
    log "Waiting... ($i/30)"
    sleep 10
done

# Ensure nginx is working with AnythingLLM
log "Restarting nginx to ensure proper proxy setup..."
systemctl restart nginx

# Final status check
log "Performing final status check..."
echo "=== Final Status ===" >> /var/log/package-versions.log
systemctl is-active docker >> /var/log/package-versions.log
systemctl is-active nginx >> /var/log/package-versions.log
docker ps >> /var/log/package-versions.log

# Mark setup as complete
echo "COMPLETE" > "$SETUP_LOCK"
log "=== AI POC Setup Complete ==="