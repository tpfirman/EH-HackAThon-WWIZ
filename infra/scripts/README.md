# AI POC Infrastructure Scripts

This directory contains external setup scripts for the AI POC CloudFormation deployment. These scripts are hosted on GitHub and downloaded during EC2 instance initialization to prevent UserData changes from triggering instance replacement.

## Key Features

- **Idempotent**: All scripts are safe to re-run multiple times without causing issues
- **Logging**: Comprehensive logging with timestamps for debugging
- **Status Tracking**: Setup progress tracking with lock files
- **Error Handling**: Robust error handling and graceful failures
- **Service Checks**: Proper checks before installing/starting services

## Scripts

### setup-ai-poc.sh
Main setup script that configures the entire AI POC environment:
- **Idempotent**: Checks existing installations and skips if already present
- **Progress Tracking**: Uses lock file to track setup completion
- **Service Management**: Safely starts/restarts services as needed
- Installs Docker, nginx, OpenSSL with version checks
- Sets up AnythingLLM with dynamic memory allocation and container restart handling
- Configures nginx proxy with health endpoint and backup configurations
- Sets up CloudWatch logging with backup of original configs
- Handles all environment variables from CloudFormation

### check-status.sh
System status check script that displays:
- **Robust Checks**: Handles missing commands/services gracefully
- **Timeouts**: Uses timeouts for network requests to prevent hanging
- **Setup Status**: Shows setup completion status and progress
- System resources (memory, disk, load)
- Docker container status and resource usage
- Nginx status and health check responses
- AnythingLLM connectivity and response codes
- Recent error logs analysis
- Network connectivity tests (Internet, AWS services)

### cleanup.sh
Cleanup script for graceful resource cleanup:
- **Safe Operations**: Checks for service existence before operations
- **Complete Cleanup**: Removes setup locks to allow fresh installation
- **Logging**: Logs all cleanup operations with timestamps
- Stops and removes Docker containers
- Cleans up Docker images (preserving base images)
- Clears application and system logs
- Stops services gracefully
- Resets setup state for fresh deployments

### connect-info.sh
Connection information script that shows:
- Instance details and IP addresses
- Load Balancer URLs and endpoints
- Service status summary
- Resource allocation information
- Configuration details
- Quick access commands for troubleshooting

## Usage in CloudFormation

The CloudFormation template now uses a minimal UserData section that:
1. Downloads the main setup script from GitHub (`infra/scripts/setup-ai-poc.sh`)
2. Executes it with all required environment variables
3. Downloads utility scripts to `/usr/local/bin/` for easy access

## Re-run Safety (Idempotent Design)

All scripts can be safely re-run without issues:

```bash
# Safe to run multiple times
/usr/local/bin/check-status.sh

# Safe to run for cleanup and fresh setup
/usr/local/bin/cleanup.sh
curl -fsSL "https://raw.githubusercontent.com/tpfirman/EH-HackAThon-WWIZ/WIP/infra/scripts/setup-ai-poc.sh" | bash

# Safe to run for connection info
/usr/local/bin/connect-info.sh
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
