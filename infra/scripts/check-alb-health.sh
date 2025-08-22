#!/bin/bash

echo "=== ALB Health Check Diagnostics ==="
echo "Date: $(date)"
echo

echo "1. Testing local health endpoint..."
echo "----------------------------------------"
curl -s http://localhost/health | jq . || curl -s http://localhost/health
echo
echo

echo "2. Testing direct AnythingLLM connection..."
echo "----------------------------------------"
curl -s http://localhost:3001 | head -n 5
echo
echo

echo "3. Checking nginx status..."
echo "----------------------------------------"
sudo systemctl status nginx --no-pager -l
echo
echo

echo "4. Checking nginx error logs (last 10 lines)..."
echo "----------------------------------------"
sudo tail -n 10 /var/log/nginx/error.log
echo
echo

echo "5. Checking nginx access logs (last 5 lines)..."
echo "----------------------------------------"
sudo tail -n 5 /var/log/nginx/access.log
echo
echo

echo "6. Checking if nginx is listening on port 80..."
echo "----------------------------------------"
sudo netstat -tlnp | grep :80
echo
echo

echo "7. Checking AnythingLLM container status..."
echo "----------------------------------------"
sudo docker ps | grep anythingllm
echo
echo

echo "8. Testing health endpoint response headers..."
echo "----------------------------------------"
curl -I http://localhost/health
echo
echo

echo "=== Diagnostic complete ==="
