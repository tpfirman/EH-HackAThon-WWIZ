#!/bin/bash
# AI POC Setup Script - External version to avoid CloudFormation UserData changes
# This script is pulled from GitHub to prevent instance replacement on updates
# IDEMPOTENT: Safe to re-run multiple times
# MUST RUN AS ROOT

# Exit on any error for POC simplicity
set -e

# Color definitions for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Create lock file to track setup progress
SETUP_LOCK="/var/log/ai-poc-setup.lock"
SETUP_LOG="/var/log/ai-poc-setup.log"

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

echo -e "${CYAN}=== AI POC Setup Starting ===${NC}" | tee -a "$SETUP_LOG"
echo "Timestamp: $(date)" | tee -a "$SETUP_LOG"
echo "Memory Percent: ${CF_MEMORY_PERCENT:-70}" | tee -a "$SETUP_LOG"
echo "Region: ${CF_REGION_NAME:-Sydney}" | tee -a "$SETUP_LOG"
echo "Spot Instance: ${CF_USE_SPOT:-true}" | tee -a "$SETUP_LOG"
echo "Stack: ${CF_STACK_NAME:-unknown}" | tee -a "$SETUP_LOG"

# Enhanced logging functions with colors
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}INFO${NC}: $1" | tee -a "$SETUP_LOG"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING${NC}: $1" | tee -a "$SETUP_LOG"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR${NC}: $1" | tee -a "$SETUP_LOG"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS${NC}: $1" | tee -a "$SETUP_LOG"
}

log_step() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}STEP${NC}: $1" | tee -a "$SETUP_LOG"
}

# Error handling function
handle_error() {
    local exit_code=$1
    local command="$2"
    local context="$3"

    if [ $exit_code -ne 0 ]; then
        log_error "Command failed with exit code $exit_code"
        log_error "Failed command: $command"
        log_error "Context: $context"
        return $exit_code
    fi
    return 0
}

# Function to run docker compose with fallback and error handling
docker_compose() {
    local operation="$1"
    shift
    local args="$@"

    log_step "Executing Docker Compose operation: $operation $args"

    # Try docker compose first (v2)
    if docker compose version &> /dev/null 2>&1; then
        local cmd="docker compose $operation $args"
        log "Using Docker Compose v2: $cmd"

        if ! eval "$cmd" 2>&1 | tee -a "$SETUP_LOG"; then
            local exit_code=${PIPESTATUS[0]}
            handle_error $exit_code "$cmd" "Docker Compose v2 operation"
            return $exit_code
        fi
        log_success "Docker Compose v2 operation completed successfully"
        return 0

    # Fallback to docker-compose (v1)
    elif command -v docker-compose &> /dev/null; then
        local cmd="docker-compose $operation $args"
        log "Using Docker Compose v1: $cmd"

        if ! eval "$cmd" 2>&1 | tee -a "$SETUP_LOG"; then
            local exit_code=${PIPESTATUS[0]}
            handle_error $exit_code "$cmd" "Docker Compose v1 operation"
            return $exit_code
        fi
        log_success "Docker Compose v1 operation completed successfully"
        return 0
    else
        log_error "Neither 'docker compose' nor 'docker-compose' is available"
        return 1
    fi
}

# Safe Docker command execution with error handling
safe_docker() {
    local cmd="$@"
    log_step "Executing Docker command: $cmd"

    local output
    local exit_code

    # Capture both stdout and stderr
    if output=$(eval "$cmd" 2>&1); then
        exit_code=0
        log_success "Docker command completed successfully"
        echo "$output" | tee -a "$SETUP_LOG"
        return 0
    else
        exit_code=$?
        log_error "Docker command failed with exit code $exit_code"
        log_error "Command: $cmd"
        log_error "Output: $output"
        echo "$output" | tee -a "$SETUP_LOG"
        return $exit_code
    fi
}

# Check if already fully set up
if [ -f "$SETUP_LOCK" ] && [ "$(cat $SETUP_LOCK)" = "COMPLETE" ]; then
    log_step "Setup already completed. Checking services..."

    # Quick health check of services with error handling
    if command -v docker &> /dev/null && systemctl is-active --quiet docker && systemctl is-active --quiet nginx; then
        if docker ps --filter name=anythingllm --quiet &> /dev/null; then
            log_success "All services running. Setup verification complete."
            exit 0
        else
            log_warning "AnythingLLM container not running, will restart services"
        fi
    else
        log_warning "Docker or nginx services not active or not installed"
    fi
    log_step "Services need restart. Continuing with setup..."
fi

echo "RUNNING" > "$SETUP_LOCK"

# Install essential packages including curl for health checks
log_step "Updating system packages..."

# Update packages with error tolerance
if yum update -y 2>&1 | tee -a "$SETUP_LOG"; then
    log_success "System packages updated successfully"
else
    log_warning "System package update had issues, continuing..."
fi

if yum update -y amazon-linux-extras 2>&1 | tee -a "$SETUP_LOG"; then
    log_success "Amazon Linux extras updated successfully"
else
    log_warning "Amazon Linux extras update had issues, continuing..."
fi

if amazon-linux-extras enable openssl11 2>&1 | tee -a "$SETUP_LOG"; then
    log_success "OpenSSL11 enabled successfully"
else
    log_warning "OpenSSL11 enable had issues, continuing..."
fi

if yum clean metadata 2>&1 | tee -a "$SETUP_LOG"; then
    log_success "YUM metadata cleaned successfully"
else
    log_warning "YUM clean had issues, continuing..."
fi

log_step "Installing essential packages..."
if yum install -y curl 2>&1 | tee -a "$SETUP_LOG"; then
    log_success "Essential packages installed successfully"
else
    log_error "Failed to install essential packages - this may cause issues"
    # Don't exit here, try to continue
fi


# Install Docker if not present
log_step "Installing Docker..."
if ! command -v docker &> /dev/null; then
    log "Docker not found, installing via amazon-linux-extras..."
    amazon-linux-extras install docker=latest -y
    log_success "Docker installed"
else
    log "Docker already installed"
fi

# Start and enable Docker service
log_step "Starting Docker service..."
systemctl start docker
systemctl enable docker
log_success "Docker service started and enabled"

# Add ec2-user to docker group
log_step "Adding ec2-user to docker group..."
usermod -a -G docker ec2-user
log_success "ec2-user added to docker group"

# Install Docker Compose
log_step "Installing Docker Compose..."
if ! docker compose version &> /dev/null; then
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

    log_success "Docker Compose installed"
else
    log "Docker Compose already available"
fi

# Simple Docker verification
log_step "Verifying Docker installation..."
if ! systemctl is-active docker &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 1
fi

# Test basic Docker access
if docker version &> /dev/null; then
    log_success "Docker is running and accessible"
else
    log_error "Docker verification failed"
    exit 1
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
fi

# Create AnythingLLM setup script with dynamic memory allocation
log "Creating AnythingLLM setup script..."
mkdir -p /home/ec2-user/anythingllm/{logs,storage}

cat << 'EOF' > /home/ec2-user/setup-anythingllm.sh
#!/bin/bash

# Setup logging (inherit from parent script setup)
SETUP_LOG="${SETUP_LOG:-/var/log/ai-poc-setup.log}"

# Color definitions for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}INFO${NC}: $1" | tee -a "$SETUP_LOG"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING${NC}: $1" | tee -a "$SETUP_LOG"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR${NC}: $1" | tee -a "$SETUP_LOG"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS${NC}: $1" | tee -a "$SETUP_LOG"
}

log_step() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${BLUE}STEP${NC}: $1" | tee -a "$SETUP_LOG"
}

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
    mem_limit: ${ANYTHINGLLM_MEMORY_MB}m
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

volumes:
  anythingllm_storage:
  anythingllm_logs:
DOCKER_COMPOSE_EOF

# Set correct ownership with error handling
log_step "Setting file ownership for AnythingLLM..."
if ! chown -R ec2-user:ec2-user /home/ec2-user/anythingllm 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "Failed to set ownership for AnythingLLM directory"
    exit 1
fi
log_success "File ownership set successfully"

# Start AnythingLLM containers
log_step "Starting AnythingLLM containers..."
cd /home/ec2-user/anythingllm

COMPOSE_SUCCESS=false
if docker compose version &> /dev/null; then
    log "Starting with Docker Compose v2..."
    if sudo -u ec2-user docker compose up -d 2>&1 | tee -a "$SETUP_LOG"; then
        log_success "AnythingLLM started with Docker Compose v2"
        COMPOSE_SUCCESS=true
    else
        log_error "Failed to start AnythingLLM with Docker Compose v2"
    fi
elif command -v docker-compose &> /dev/null; then
    log "Starting with Docker Compose v1..."
    if sudo -u ec2-user docker-compose up -d 2>&1 | tee -a "$SETUP_LOG"; then
        log_success "AnythingLLM started with Docker Compose v1"
        COMPOSE_SUCCESS=true
    else
        log_error "Failed to start AnythingLLM with Docker Compose v1"
    fi
else
    log_error "No Docker Compose found"
    exit 1
fi

if [ "$COMPOSE_SUCCESS" = "false" ]; then
    log_error "Failed to start AnythingLLM containers"
    exit 1
fi

# Verify container started
log_step "Verifying container startup..."
sleep 10

# Check if container exists and is running
CONTAINER_STATUS=$(sudo -u ec2-user docker ps --filter "name=anythingllm" --filter "status=running" --format "{{.Status}}" 2>/dev/null || echo "")
if [ -n "$CONTAINER_STATUS" ]; then
    log_success "AnythingLLM container is running: $CONTAINER_STATUS"
else
    log_error "Container not found in running state, checking all containers..."
    ALL_CONTAINERS=$(sudo -u ec2-user docker ps -a --filter "name=anythingllm" --format "{{.Names}}: {{.Status}}" 2>/dev/null || echo "None")
    log "All AnythingLLM containers: $ALL_CONTAINERS"
    
    # Try to get container logs if container exists but isn't running
    if sudo -u ec2-user docker ps -a --filter "name=anythingllm" --quiet | head -1 >/dev/null 2>&1; then
        log "Checking container logs for startup issues..."
        sudo -u ec2-user docker logs anythingllm 2>&1 | tail -20 | tee -a "$SETUP_LOG" || log_warning "Could not retrieve container logs"
    fi
    
    log_error "AnythingLLM container failed to start properly"
    exit 1
fi

echo -e "${GREEN}AnythingLLM starting with ${ANYTHINGLLM_MEMORY_MB}MB memory allocation${NC}"
echo -e "${GREEN}AI POC setup complete! Available 24/7 for testing and evaluation.${NC}"
echo -e "${CYAN}Region: ${CF_REGION_NAME:-Sydney} | Spot Instance: ${CF_USE_SPOT:-true}${NC}"
EOF

chmod +x /home/ec2-user/setup-anythingllm.sh

# Run the setup (with some delay to ensure Docker is ready)
log "Waiting for Docker to be fully ready..."
sleep 30

# Runtime Docker permission verification
runtime_docker_check() {
    log_step "Performing runtime Docker permission check..."

    # Test Docker access as ec2-user with simplified approach
    local docker_test_output
    local exit_code

    # Try direct Docker access first
    if docker_test_output=$(sudo -u ec2-user docker ps -q --no-trunc 2>&1); then
        exit_code=0
        log_success "Runtime Docker permission check passed - ec2-user can access Docker"
        return 0
    else
        exit_code=$?
        log_warning "Runtime Docker permission check encountered issues:"
        log_warning "Output: $docker_test_output"
        log_warning "This may indicate group membership needs refresh, but containers should still start via sudo"

        # Additional check: can we run Docker with sudo?
        if sudo -u ec2-user docker version &> /dev/null; then
            log_success "Fallback check passed - Docker accessible via sudo for ec2-user"
            return 0
        else
            log_error "Docker not accessible for ec2-user even with sudo"
            return 1
        fi
    fi
}

# Perform runtime check with error handling
if ! runtime_docker_check; then
    log_error "Docker permission verification failed - deployment may encounter issues"
    log_error "Continuing with deployment but manual intervention may be required"
fi

log_step "Starting AnythingLLM setup..."
if ! /home/ec2-user/setup-anythingllm.sh 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "AnythingLLM setup script failed"
    log_error "Check the setup log for detailed error information"
    exit 1
fi

# Verify that the container actually started
log_step "Verifying AnythingLLM container is running..."
sleep 5
CONTAINER_RUNNING=$(sudo -u ec2-user docker ps --filter "name=anythingllm" --filter "status=running" --quiet 2>/dev/null || echo "")
if [ -z "$CONTAINER_RUNNING" ]; then
    log_error "AnythingLLM container is not running after setup"
    log_error "Checking container status for diagnostics..."
    safe_docker "sudo -u ec2-user docker ps -a --filter name=anythingllm" || log_error "Could not check container status"
    safe_docker "sudo -u ec2-user docker logs anythingllm" || log_error "Could not retrieve container logs"
    exit 1
fi
log_success "AnythingLLM setup completed successfully - container is running"

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

# Test nginx configuration before starting with error handling
log_step "Testing nginx configuration..."
if ! nginx -t 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "Nginx configuration test failed"
    exit 1
fi
log_success "Nginx configuration test passed"

# Start and enable nginx with error handling
log_step "Starting nginx service..."
if ! systemctl enable nginx 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "Failed to enable nginx service"
    exit 1
fi

if ! systemctl start nginx 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "Failed to start nginx service"
    exit 1
fi
log_success "Nginx service started and enabled"

# Wait for AnythingLLM to be ready before finalizing
log_step "Waiting for AnythingLLM to be ready..."
READY=false
for i in {1..30}; do
    if curl -f http://localhost:3001 >/dev/null 2>&1; then
        log_success "AnythingLLM is ready!"
        READY=true
        break
    fi
    log "Waiting for AnythingLLM... ($i/30)"
    sleep 10
done

# Check if AnythingLLM is ready
if [ "$READY" = "false" ]; then
    log_error "AnythingLLM failed to become ready within timeout period"
    log_error "Checking container status for diagnostics..."
    
    # Get detailed diagnostics
    log_error "Container status check:"
    safe_docker "sudo -u ec2-user docker ps --filter name=anythingllm" || log_error "Could not check container status"
    
    log_error "Container logs (last 50 lines):"
    safe_docker "sudo -u ec2-user docker logs --tail 50 anythingllm" || log_error "Could not retrieve container logs"
    
    log_error "Docker system info:"
    safe_docker "docker system df" || log_error "Could not get Docker system info"
    
    log_error "Available memory:"
    free -h | tee -a "$SETUP_LOG"
    
    log_error "Setup failed - AnythingLLM is not responding"
    exit 1
fi

# Ensure nginx is working with AnythingLLM
log_step "Restarting nginx to ensure proper proxy setup..."
if ! systemctl restart nginx 2>&1 | tee -a "$SETUP_LOG"; then
    log_error "Failed to restart nginx"
    exit 1
fi
log_success "Nginx restarted successfully"

# Final status check and Docker permission verification
final_verification() {
    log_step "Performing final status and permission verification..."

    # Service status checks
    local docker_status=$(systemctl is-active docker 2>/dev/null || echo "inactive")
    local nginx_status=$(systemctl is-active nginx 2>/dev/null || echo "inactive")

    log "Docker service status: $docker_status"
    log "Nginx service status: $nginx_status"

    # Container status check
    local container_count=0
    local running_containers=""

    if [ "$docker_status" = "active" ]; then
        # Check containers as ec2-user
        running_containers=$(sudo -u ec2-user docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Permission denied")
        container_count=$(sudo -u ec2-user docker ps -q 2>/dev/null | wc -l || echo "0")

        log "Running containers ($container_count):"
        if [ "$running_containers" != "Permission denied" ] && [ -n "$running_containers" ]; then
            echo "$running_containers" | tee -a "$SETUP_LOG"
        else
            log_warning "Could not list containers as ec2-user - may need session refresh"
            # Fallback check as root
            local root_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "No containers")
            log "Container status (root view): $root_containers"
        fi

        # Check if AnythingLLM container is running
        local anythingllm_status=""
        anythingllm_status=$(sudo -u ec2-user docker ps --filter "name=anythingllm" --format "{{.Status}}" 2>/dev/null || echo "Not found")
        log "AnythingLLM container status: $anythingllm_status"

        # Docker group membership final check
        local docker_groups=$(groups ec2-user 2>/dev/null || echo "unknown")
        log "ec2-user group memberships: $docker_groups"

        if echo "$docker_groups" | grep -q docker; then
            log "? ec2-user is properly added to docker group"
        else
            log_warning "? ec2-user docker group membership verification failed"
        fi

        # Docker socket permissions
        local socket_perms=$(stat -c "%a" /var/run/docker.sock 2>/dev/null || echo "unknown")
        local socket_group=$(stat -c "%G" /var/run/docker.sock 2>/dev/null || echo "unknown")
        log "Docker socket permissions: $socket_perms (group: $socket_group)"
    else
        log_error "Docker service is not active - container verification skipped"
    fi

    # Health endpoint test
    log "Testing health endpoint..."
    local health_response=""
    health_response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost/health 2>/dev/null || echo "000")
    if [ "$health_response" = "200" ]; then
        log "? Health endpoint responding correctly"
    else
        log_warning "? Health endpoint not responding (HTTP: $health_response)"
    fi

    return 0
}

# Run final verification
if ! final_verification; then
    log_error "Final verification failed - some components may not be working correctly"
    exit 1
fi

log_step "Final status logging..."
echo "=== Final Status ===" >> /var/log/package-versions.log
systemctl is-active docker >> /var/log/package-versions.log
systemctl is-active nginx >> /var/log/package-versions.log
safe_docker "docker ps" >> /var/log/package-versions.log || echo "Docker ps failed" >> /var/log/package-versions.log

# Mark setup as complete
echo "COMPLETE" > "$SETUP_LOCK"
echo -e "${GREEN}${WHITE}=== AI POC Setup Complete ===${NC}"
echo -e "${CYAN}All services started successfully with enhanced error handling!${NC}"
echo -e "${BLUE}Access your AI POC at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)${NC}"
log_success "=== AI POC Setup Complete ==="
