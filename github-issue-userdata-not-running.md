# EC2 User Data Script Not Executing Automatically During Deployment

## Issue Description
The `setup-ai-poc.sh` script is not executing automatically when EC2 instances are launched via CloudFormation, requiring manual execution on the instance.

## Expected Behavior
- EC2 instances should automatically execute the setup script during launch
- The script should run via CloudFormation UserData and complete setup without manual intervention
- Target group registration should happen automatically for spot instances

## Current Behavior
- EC2 instances launch successfully but setup script doesn't execute
- Manual execution required: `sudo chmod +x infra/scripts/*.sh && sudo ./infra/scripts/setup-ai-poc.sh 2>&1 | tee /var/log/ai-poc-git-setup.log`
- Target group registration fails because setup doesn't complete

## Investigation Needed
1. **UserData Script Execution**: Check if the CloudFormation UserData is properly formatted and executing
2. **Git Repository Access**: Verify the EC2 instance can access the GitHub repository during launch
3. **Script Permissions**: Ensure scripts have proper execute permissions when downloaded
4. **CloudFormation Signal**: Check if the CreationPolicy ResourceSignal is timing out

## Possible Root Causes
- UserData script formatting issues (line endings, encoding)
- GitHub repository access issues during EC2 launch
- Missing IAM permissions for repository access
- Script execution failures not being logged properly
- CreationPolicy timeout causing premature failure

## Files to Review
- `infra/wwiz-cloudformation.yaml` - UserData section in LaunchTemplate
- `infra/scripts/setup-ai-poc.sh` - Main setup script
- CloudWatch logs for EC2 instance startup
- `/var/log/cloud-init-output.log` on EC2 instance

## Priority
**Medium** - Workaround exists (manual execution) but automation is important for production deployments

## Labels
- `bug`
- `infrastructure` 
- `cloudformation`
- `deployment`

## Next Steps
1. Check CloudWatch logs for UserData execution
2. Review cloud-init logs on EC2 instance
3. Verify GitHub repository access during launch
4. Test UserData script formatting and permissions
