# Spot Instance Target Group Auto-Registration Failing

## Issue Description
Spot instances are not automatically registering themselves with the ALB target group, causing 503 errors until manual registration is performed.

## Expected Behavior
- Spot instances should automatically register with the target group after setup completion
- The `setup-ai-poc.sh` script should handle target group registration for spot instances
- No manual intervention should be required for target registration

## Current Behavior
- Spot instances launch and run setup successfully
- Target group registration code in setup script fails silently
- Manual registration required: `aws elbv2 register-targets --target-group-arn <arn> --targets Id=<instance-id>`
- ALB returns 503 errors until manual registration

## Investigation Required
1. **IAM Permissions**: Check if EC2 instance role has ELB permissions
2. **Environment Variables**: Verify `CF_TARGET_GROUP_ARN` is properly passed to instance
3. **Script Execution**: Check if registration code section executes
4. **AWS CLI**: Verify AWS CLI is available and configured on instance

## Current Workaround
Manual target registration works:
```bash
aws elbv2 register-targets \
  --target-group-arn "arn:aws:elasticloadbalancing:ap-southeast-2:523552835634:targetgroup/ai-poc-anythingllm-ai-poc-tg/d0c43fc6841bf5a3" \
  --targets Id="<instance-id>" \
  --region ap-southeast-2
```

## Files to Review
- `infra/scripts/setup-ai-poc.sh` - Lines 441-464 (target group registration logic)
- `infra/wwiz-cloudformation.yaml` - EC2Role IAM permissions
- `/var/log/ai-poc-git-setup.log` - Setup script logs on EC2 instance

## Required IAM Permissions
The EC2 instance role likely needs:
```json
{
    "Effect": "Allow",
    "Action": [
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DescribeTargetHealth"
    ],
    "Resource": "*"
}
```

## Priority
**High** - Required for production automation and spot instance reliability

## Labels
- `bug`
- `infrastructure`
- `spot-instances`
- `target-group`
- `automation`
