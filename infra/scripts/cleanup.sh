#!/bin/bash
# Cleanup script for AI POC stack resources
# This script can be used to clean up resources before terminating the stack
# IDEMPOTENT: Safe to re-run multiple times

set -e

CLEANUP_LOG="/var/log/ai-poc-cleanup.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$CLEANUP_LOG"
}

log "=== AI POC Cleanup Starting ==="

# Stop running containers
if command -v docker &> /dev/null && docker ps -q 2>/dev/null; then
    log "Stopping running containers..."
    docker stop $(docker ps -q) 2>/dev/null || true
else
    log "No running containers found or Docker not available"
fi

# Remove containers
if command -v docker &> /dev/null && docker ps -aq 2>/dev/null; then
    log "Removing containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
else
    log "No containers to remove or Docker not available"
fi

# Remove unused images (keep base images for faster restart)
if command -v docker &> /dev/null; then
    log "Cleaning up unused Docker images..."
    docker image prune -f 2>/dev/null || true
else
    log "Docker not available, skipping image cleanup"
fi

# Clear nginx logs
if [ -f /var/log/nginx/access.log ]; then
    log "Clearing nginx logs..."
    truncate -s 0 /var/log/nginx/access.log 2>/dev/null || true
    truncate -s 0 /var/log/nginx/error.log 2>/dev/null || true
else
    log "No nginx logs found to clear"
fi

# Clear AnythingLLM logs
if [ -d /home/ec2-user/anythingllm/logs ]; then
    log "Clearing AnythingLLM logs..."
    find /home/ec2-user/anythingllm/logs -name "*.log" -type f -exec truncate -s 0 {} + 2>/dev/null || true
else
    log "No AnythingLLM logs found to clear"
fi

# Stop services gracefully
log "Stopping services..."
systemctl stop nginx 2>/dev/null || log "nginx service already stopped or not available"
systemctl stop docker 2>/dev/null || log "docker service already stopped or not available"

# Remove setup lock to allow fresh setup
if [ -f /var/log/ai-poc-setup.lock ]; then
    log "Removing setup lock file..."
    rm -f /var/log/ai-poc-setup.lock
fi

log "=== AI POC Cleanup Complete ==="
