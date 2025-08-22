# AI POC Infrastructure Scripts

This directory contains the production scripts and configuration files for the AI POC deployment.

## Current Status: **PRODUCTION READY** ✅

All scripts have been cleaned up and are production-ready. Emergency/workaround scripts have been removed.

## Scripts Overview

### 🚀 Core Production Scripts

#### `setup-ai-poc.sh` (21KB)
Main setup script that configures the entire AI POC environment:
- **Idempotent**: Safe to re-run multiple times
- **Progress Tracking**: Uses lock files to track completion
- **Target Group Registration**: Auto-registers spot instances with ALB
- Installs Docker, nginx, CloudWatch logging
- Configures AnythingLLM with proper memory allocation
- Sets up nginx proxy with health endpoints
- Handles all CloudFormation environment variables

#### `setup-anythingllm.sh` (4KB) 
Container-specific setup script:
- **Container Management**: Starts and manages AnythingLLM container
- **Health Checks**: Validates container health before completion
- **Logging**: Comprehensive logging for troubleshooting
- External configuration using `docker-compose.yml`

### 🔧 Operations & Maintenance Scripts

#### `check-alb-health.sh` (1KB)
ALB health diagnostics script:
- Tests local health endpoints
- Validates AnythingLLM connectivity
- Checks nginx and container status
- Provides comprehensive health report

#### `check-status.sh` (6KB)
Comprehensive system status checker:
- System resources (memory, disk, load)
- Docker container status and health
- Nginx status and health responses
- AnythingLLM connectivity tests
- Network connectivity validation
- Recent error log analysis

#### `cleanup.sh` (2KB)
Resource cleanup for stack termination:
- **Safe Operations**: Graceful service shutdown
- **Complete Cleanup**: Removes containers and logs
- **Reset State**: Clears setup locks for fresh deployment
- Preserves base Docker images

#### `connect-info.sh` (3KB)
Connection and instance information:
- Instance metadata and details
- Network configuration
- Service endpoints and URLs
- Access information for troubleshooting

## Configuration Files

### `nginx.conf` (1.7KB)
Production nginx configuration:
- Health endpoint at `/health`
- Reverse proxy to AnythingLLM on port 3001
- Proper headers and connection handling
- SELinux compatibility

### `docker-compose.yml` (600B)
AnythingLLM container configuration:
- Health checks and restart policies
- Memory limits and environment variables
- Port mapping and volume mounts
- Production-ready settings

### `awslogs.conf` (428B)
CloudWatch logging configuration:
- System and application log groups
- Log retention and formatting
- Integration with AWS CloudWatch
## Usage

### Production Deployment
Scripts are automatically executed via CloudFormation UserData during EC2 instance launch.

### Manual Execution
For troubleshooting or manual setup:

```bash
# Run main setup
sudo chmod +x infra/scripts/*.sh
sudo ./infra/scripts/setup-ai-poc.sh

# Check system status
./infra/scripts/check-status.sh

# Get connection information
./infra/scripts/connect-info.sh

# Check ALB health (diagnostics)
./infra/scripts/check-alb-health.sh

# Cleanup for fresh deployment
sudo ./infra/scripts/cleanup.sh
```

### Idempotent Design
All scripts can be safely re-run multiple times:
- **Setup scripts**: Check existing installations and skip if present
- **Status scripts**: Always safe to run for current state
- **Cleanup scripts**: Handle missing resources gracefully

## Integration

### CloudFormation
Scripts integrate with CloudFormation via environment variables:
- `CF_STACK_NAME` - CloudFormation stack name
- `CF_TARGET_GROUP_ARN` - ALB target group for registration
- `CF_MEMORY_PERCENT` - Memory allocation percentage
- `CF_USE_SPOT` - Spot instance flag for auto-registration

### Logging
All scripts log to:
- **Setup:** `/var/log/ai-poc-git-setup.log`
- **Status:** `/var/log/ai-poc-status.log`
- **Cleanup:** `/var/log/ai-poc-cleanup.log`

## Known Issues

For current automation issues and improvements, see:
- [GitHub Issues](https://github.com/tpfirman/EH-HackAThon-WWIZ/issues)
- [UserData Script Not Executing](../../github-issue-userdata-not-running.md)
- [Target Group Registration](../../github-issue-target-group-registration.md)

**Alternative if repository already exists:**
```bash
# If repo already cloned, just pull latest and run
cd /home/ec2-user/EH-HackAThon-WWIZ && git pull && sudo ./infra/scripts/setup-ai-poc.sh
```

## Logging

All operations are logged with timestamps:
- Setup: `/var/log/ai-poc-setup.log`
- Status: `/var/log/ai-poc-status.log` 
- Cleanup: `/var/log/ai-poc-cleanup.log`
- Lock file: `/var/log/ai-poc-setup.lock`

## Benefits

- **No Instance Replacement**: Changes to setup logic don't trigger CloudFormation instance replacement
- **Version Control**: Scripts are version controlled and can be updated independently
- **Branch Support**: Can specify different GitHub branches (WIP, main, etc.)
- **Easier Debugging**: Scripts can be tested and updated without full stack redeployment
- **Modular**: Individual utility scripts for different operations
- **Production Ready**: Robust error handling and idempotent operations
- **Maintenance Friendly**: Easy to update and troubleshoot running systems

## GitHub Integration

Scripts are pulled from: `https://github.com/tpfirman/EH-HackAThon-WWIZ.git`

Path: `infra/scripts/`
Branch can be specified via the `GitHubBranch` CloudFormation parameter (default: WIP)
