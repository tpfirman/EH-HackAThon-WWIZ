#!/bin/bash
# Debug script to troubleshoot AI POC setup issues
# Run this on the EC2 instance to diagnose setup problems

echo "=== AI POC Setup Debug Information ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo

echo "=== Environment Variables ==="
env | grep CF_ || echo "No CF_ environment variables found"
echo

echo "=== System Information ==="
echo "OS Version:"
cat /etc/os-release
echo
echo "Available memory:"
free -h
echo
echo "Disk space:"
df -h
echo

echo "=== Log Files Check ==="
if [ -f /var/log/ai-poc-setup.log ]; then
    echo "Setup log found - last 20 lines:"
    tail -20 /var/log/ai-poc-setup.log
else
    echo "Setup log NOT found at /var/log/ai-poc-setup.log"
fi
echo

if [ -f /var/log/ai-poc-git-setup.log ]; then
    echo "Git setup log found - last 20 lines:"
    tail -20 /var/log/ai-poc-git-setup.log
else
    echo "Git setup log NOT found at /var/log/ai-poc-git-setup.log"
fi
echo

if [ -f /var/log/cloud-init-output.log ]; then
    echo "Cloud-init log found - last 20 lines:"
    tail -20 /var/log/cloud-init-output.log
else
    echo "Cloud-init log NOT found"
fi
echo

echo "=== Lock File Status ==="
if [ -f /var/log/ai-poc-setup.lock ]; then
    echo "Lock file exists with content:"
    cat /var/log/ai-poc-setup.lock
else
    echo "Lock file NOT found"
fi
echo

echo "=== Repository Check ==="
if [ -d /home/ec2-user/EH-HackAThon-WWIZ ]; then
    echo "Repository directory exists"
    echo "Contents:"
    ls -la /home/ec2-user/EH-HackAThon-WWIZ/
    echo
    if [ -f /home/ec2-user/EH-HackAThon-WWIZ/infra/scripts/setup-ai-poc.sh ]; then
        echo "Setup script exists and is:"
        ls -la /home/ec2-user/EH-HackAThon-WWIZ/infra/scripts/setup-ai-poc.sh
        echo "First 10 lines of setup script:"
        head -10 /home/ec2-user/EH-HackAThon-WWIZ/infra/scripts/setup-ai-poc.sh
    else
        echo "Setup script NOT found in repository"
    fi
else
    echo "Repository directory NOT found"
fi
echo

echo "=== Docker Status ==="
if command -v docker &> /dev/null; then
    echo "Docker command found:"
    docker --version
    echo "Docker service status:"
    systemctl status docker --no-pager
else
    echo "Docker command NOT found"
fi
echo

echo "=== YUM and Amazon Linux Extras Status ==="
echo "YUM available:"
command -v yum && echo "YES" || echo "NO"
echo "Amazon Linux Extras available:"
command -v amazon-linux-extras && echo "YES" || echo "NO"
echo

echo "=== Network Connectivity ==="
echo "Can reach GitHub:"
curl -s --max-time 10 https://github.com && echo "YES" || echo "NO"
echo "Can reach Docker Hub:"
curl -s --max-time 10 https://registry-1.docker.io && echo "YES" || echo "NO"
echo

echo "=== Running Processes ==="
echo "Looking for setup-related processes:"
ps aux | grep -E "(setup|docker|nginx)" | grep -v grep
echo

echo "=== Recent System Messages ==="
echo "Last 10 lines from /var/log/messages:"
if [ -f /var/log/messages ]; then
    tail -10 /var/log/messages
else
    echo "/var/log/messages not found"
fi

echo
echo "=== Debug Information Complete ==="
echo "To manually run setup: sudo /home/ec2-user/EH-HackAThon-WWIZ/infra/scripts/setup-ai-poc.sh"
echo "To check status: sudo /usr/local/bin/check-status.sh"
