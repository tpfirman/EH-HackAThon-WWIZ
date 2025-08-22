#!/bin/bash
# Status check script for AI POC deployment
# This script checks the health of all components
# IDEMPOTENT: Safe to re-run multiple times

# Color definitions for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Colo

STATUS_LOG="/var/log/ai-poc-status.log"

# Enhanced logging functions with colors
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}INFO${NC}: $1" | tee -a "$STATUS_LOG"
}

log_warning() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING${NC}: $1" | tee -a "$STATUS_LOG"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR${NC}: $1" | tee -a "$STATUS_LOG"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}SUCCESS${NC}: $1" | tee -a "$STATUS_LOG"
}

echo -e "${CYAN}=== AI POC Status Check ===${NC}"
echo "Timestamp: $(date)"
echo "Instance: $(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'N/A')"
echo

# Check system resources
echo -e "${BLUE}=== System Resources ===${NC}"
echo "Memory:"
free -h
echo
echo "Disk Space:"
df -h / /tmp
echo
echo "Load Average:"
uptime
echo

# Check Docker status
echo -e "${BLUE}=== Docker Status ===${NC}"
if command -v docker &> /dev/null && systemctl is-active --quiet docker; then
    echo -e "${GREEN}Docker Service: RUNNING${NC}"
    
    # Check Docker daemon info
    echo "Docker Version:"
    docker version --format "Server: {{.Server.Version}}, Client: {{.Client.Version}}" 2>/dev/null || echo -e "${RED}Version check failed${NC}"
    
    echo "Docker Containers:"
    if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; then
        echo -e "${GREEN}Container list retrieved successfully${NC}"
    else
        echo -e "${RED}Error getting container list${NC}"
    fi
    echo
    
    echo "Docker Resource Usage:"
    if docker stats --no-stream 2>/dev/null; then
        echo -e "${GREEN}Resource stats retrieved successfully${NC}"
    else
        echo -e "${RED}Error getting container stats${NC}"
    fi
    echo
    
    # Check Docker permissions for ec2-use
    echo -e "${PURPLE}=== Docker User Permissions ===${NC}"
    echo "ec2-user groups: $(groups ec2-user 2>/dev/null || echo 'User not found')"
    
    # Check if ec2-user can access Docke
    local docker_access_test=""
    docker_access_test=$(sudo -u ec2-user docker version --format "{{.Client.Version}}" 2>/dev/null || echo "Access denied")
    if [ "$docker_access_test" != "Access denied" ]; then
        echo "ec2-user Docker access: ✓ WORKING (Client: $docker_access_test)"
    else
        echo "ec2-user Docker access: ✗ FAILED"
        echo "This may indicate group membership needs refresh or permission issues"
    fi
    
    # Check Docker socket permissions
    if [ -S "/var/run/docker.sock" ]; then
        local socket_perms=$(stat -c "%a" /var/run/docker.sock 2>/dev/null)
        local socket_group=$(stat -c "%G" /var/run/docker.sock 2>/dev/null)
        echo "Docker socket: permissions=$socket_perms, group=$socket_group"
    else
        echo "Docker socket: NOT FOUND"
    fi
    
    # Check specific AnythingLLM containe
    local anythingllm_container=""
    anythingllm_container=$(docker ps --filter "name=anythingllm" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    echo "AnythingLLM container: $anythingllm_container"
    
else
    echo "Docker Service: STOPPED/FAILED or not installed"
fi
echo

# Check nginx status
echo "=== Nginx Status ==="
if command -v nginx &> /dev/null && systemctl is-active --quiet nginx; then
    echo "Nginx Service: RUNNING"
    echo "Health Check Response:"
    curl -s --max-time 10 http://localhost/health | jq . 2>/dev/null || echo "Health check failed or jq not available"
else
    echo "Nginx Service: STOPPED/FAILED or not installed"
fi
echo

# Check AnythingLLM connectivity
echo "=== AnythingLLM Status ==="
if curl -f -s --max-time 10 http://localhost:3001 >/dev/null 2>&1; then
    echo "AnythingLLM: ACCESSIBLE"
    echo "Direct Response Code: $(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://localhost:3001 2>/dev/null || echo 'N/A')"
else
    echo "AnythingLLM: NOT ACCESSIBLE"
fi
echo

# Check recent logs for errors
echo "=== Recent Log Errors ==="
echo "System Errors (last 5):"
journalctl --since "1 hour ago" --priority=err --no-pager -n 5 2>/dev/null || echo "No recent errors"
echo
echo "Nginx Errors (last 5):"
tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo "No nginx errors"
echo

# Check CloudWatch logs agent
echo "=== CloudWatch Logs ==="
if systemctl is-active --quiet awslogsd; then
    echo "CloudWatch Logs Agent: RUNNING"
else
    echo "CloudWatch Logs Agent: STOPPED/FAILED"
fi
echo

# Network connectivity check
echo "=== Network Connectivity ==="
echo "Internet Access:"
if curl -s --max-time 5 http://www.google.com >/dev/null 2>&1; then
    echo "✓ Internet: OK"
else
    echo "✗ Internet: FAILED"
fi

echo "AWS Services Access:"
if curl -s --max-time 5 https://bedrock-runtime.ap-southeast-2.amazonaws.com >/dev/null 2>&1; then
    echo "✓ Bedrock: OK"
else
    echo "✗ Bedrock: FAILED"
fi
echo

# Check setup status
echo "=== Setup Status ==="
if [ -f /var/log/ai-poc-setup.lock ]; then
    SETUP_STATUS=$(cat /var/log/ai-poc-setup.lock)
    echo "Setup Lock Status: $SETUP_STATUS"
    if [ "$SETUP_STATUS" = "COMPLETE" ]; then
        echo "✓ Initial setup completed successfully"
    else
        echo "⚠ Setup in progress or failed"
    fi
else
    echo "⚠ No setup lock file found - setup may not have run"
fi

echo "=== Status Check Complete ==="
