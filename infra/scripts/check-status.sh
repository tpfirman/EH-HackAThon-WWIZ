#!/bin/bash
# Status check script for AI POC deployment
# This script checks the health of all components
# IDEMPOTENT: Safe to re-run multiple times

STATUS_LOG="/var/log/ai-poc-status.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$STATUS_LOG"
}

echo "=== AI POC Status Check ==="
echo "Timestamp: $(date)"
echo "Instance: $(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'N/A')"
echo

# Check system resources
echo "=== System Resources ==="
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
echo "=== Docker Status ==="
if command -v docker &> /dev/null && systemctl is-active --quiet docker; then
    echo "Docker Service: RUNNING"
    echo "Docker Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Error getting container list"
    echo
    echo "Docker Resource Usage:"
    docker stats --no-stream 2>/dev/null || echo "Error getting container stats"
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
