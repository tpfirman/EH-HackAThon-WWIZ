#!/bin/bash
# AnythingLLM Container Setup Script
# Called from setup-ai-poc.sh with proper environment

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

# Setup logging
SETUP_LOG="${SETUP_LOG:-/var/log/ai-poc-setup.log}"

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

# Memory allocation (passed from main script)
ANYTHINGLLM_MEMORY_MB="${ANYTHINGLLM_MEMORY_MB:-2048}"
ANYTHINGLLM_MEMORY_RESERVATION_MB="${ANYTHINGLLM_MEMORY_RESERVATION_MB:-1024}"

log_step "Starting AnythingLLM container setup..."
log "Memory allocation: ${ANYTHINGLLM_MEMORY_MB}MB limit"

# Create docker-compose.yml for AnythingLLM with dynamic memory
mkdir -p /home/ec2-user/anythingllm/{logs,storage}
cd /home/ec2-user/anythingllm

# Stop existing container if running
if docker ps | grep -q anythingllm; then
    log "Stopping existing AnythingLLM container..."
    docker stop anythingllm || true
    docker rm anythingllm || true
fi

# Verify docker-compose.yml exists (should be copied by main script)
if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml not found in /home/ec2-user/anythingllm/"
    exit 1
fi

log_step "Using Docker Compose configuration from file..."
log "Docker Compose file contents:"
cat docker-compose.yml | tee -a "$SETUP_LOG"

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

if docker compose version &> /dev/null; then
    log "Starting with Docker Compose v2..."
    sudo -u ec2-user docker compose up -d
    log_success "AnythingLLM started with Docker Compose v2"
elif command -v docker-compose &> /dev/null; then
    log "Starting with Docker Compose v1..."
    sudo -u ec2-user docker-compose up -d
    log_success "AnythingLLM started with Docker Compose v1"
else
    log_error "No Docker Compose found"
    exit 1
fi

# Verify container started
log_step "Verifying container startup..."
sleep 5

# Check if container exists and is running
CONTAINER_STATUS=$(sudo -u ec2-user docker ps --filter "name=anythingllm" --format "{{.Status}}" 2>/dev/null || echo "")
if [ -n "$CONTAINER_STATUS" ]; then
    log_success "AnythingLLM container is running: $CONTAINER_STATUS"
else
    log_warning "Container not found in running state, checking all containers..."
    ALL_CONTAINERS=$(sudo -u ec2-user docker ps -a --filter "name=anythingllm" --format "{{.Names}}: {{.Status}}" 2>/dev/null || echo "None")
    log "All AnythingLLM containers: $ALL_CONTAINERS"
    
    # Try to get container logs if container exists but isn't running
    if sudo -u ec2-user docker ps -a --filter "name=anythingllm" --quiet | head -1 >/dev/null 2>&1; then
        log "Checking container logs for startup issues..."
        sudo -u ec2-user docker logs anythingllm 2>&1 | tail -20 | tee -a "$SETUP_LOG" || log_warning "Could not retrieve container logs"
    fi
    
    # Exit with error if container isn't running
    exit 1
fi

log_success "AnythingLLM container setup completed successfully"
echo -e "${GREEN}AnythingLLM starting with ${ANYTHINGLLM_MEMORY_MB}MB memory allocation${NC}"
echo -e "${GREEN}AI POC setup complete! Available 24/7 for testing and evaluation.${NC}"
echo -e "${CYAN}Region: ${CF_REGION_NAME:-Sydney} | Spot Instance: ${CF_USE_SPOT:-true}${NC}"
