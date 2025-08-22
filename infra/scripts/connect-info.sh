#!/bin/bash
# Connection information script for AI POC
# This script provides connection details and access information

echo "=== AI POC Connection Information ==="
echo "Timestamp: $(date)"
echo

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'N/A')
INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'N/A')
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo 'N/A')
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'N/A')
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo 'N/A')

echo "=== Instance Details ==="
echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "Availability Zone: $AZ"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo

# Get Load Balancer URL (this would be passed as environment variable from CloudFormation)
if [ ! -z "$CF_ALB_DNS_NAME" ]; then
    echo "=== Load Balancer Access ==="
    echo "Primary URL: http://$CF_ALB_DNS_NAME"
    echo "Health Check: http://$CF_ALB_DNS_NAME/health"
    echo
fi

# Direct instance access (if ALB is not available)
if [ "$PUBLIC_IP" != "N/A" ]; then
    echo "=== Direct Instance Access ==="
    echo "Direct URL: http://$PUBLIC_IP"
    echo "Health Check: http://$PUBLIC_IP/health"
    echo "Note: Use Load Balancer URL for production access"
    echo
fi

# Service status summary
echo "=== Service Status Summary ==="
DOCKER_STATUS=$(systemctl is-active docker 2>/dev/null || echo "inactive")
NGINX_STATUS=$(systemctl is-active nginx 2>/dev/null || echo "inactive")
ANYTHINGLLM_STATUS="inactive"

if [ "$DOCKER_STATUS" = "active" ]; then
    if docker ps | grep -q anythingllm; then
        ANYTHINGLLM_STATUS="active"
    fi
fi

echo "Docker: $DOCKER_STATUS"
echo "Nginx: $NGINX_STATUS"
echo "AnythingLLM: $ANYTHINGLLM_STATUS"
echo

# Memory and resource info
echo "=== Resource Allocation ==="
TOTAL_MEMORY_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEMORY_MB=$((TOTAL_MEMORY_KB / 1024))
ANYTHINGLLM_MEMORY_MB=$((TOTAL_MEMORY_MB * ${CF_MEMORY_PERCENT:-70} / 100))

echo "Total Memory: ${TOTAL_MEMORY_MB}MB"
echo "AnythingLLM Allocation: ${ANYTHINGLLM_MEMORY_MB}MB (${CF_MEMORY_PERCENT:-70}%)"
echo "Instance Type: t3.small (Spot)"
echo "Region: ${CF_REGION_NAME:-ap-southeast-2 (Sydney)}"
echo

# Configuration details
echo "=== Configuration Details ==="
echo "Stack Name: ${CF_STACK_NAME:-ai-poc}"
echo "Environment: POC/Testing"
echo "Auto Cleanup Date: 2025-12-31"
echo "Bedrock Access: Enabled (streaming)"
echo "CloudWatch Logs: Enabled"
echo

# Quick access commands
echo "=== Quick Commands ==="
echo "Check Status: curl http://$PUBLIC_IP/health"
echo "View Logs: docker logs anythingllm"
echo "Restart Service: sudo docker compose restart -f /home/ec2-user/anythingllm/"
echo "System Status: systemctl status nginx docker"
echo

echo "=== Ready for AI POC Testing ==="
