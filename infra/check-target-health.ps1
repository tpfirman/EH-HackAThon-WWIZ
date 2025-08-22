#!/usr/bin/env powershell
# CloudFormation ALB Target Group Health Checker

$StackName = "ai-poc-anythingllm"
$Region = "ap-southeast-2"

Write-Host "=== ALB Target Group Health Diagnostics ===" -ForegroundColor Cyan
Write-Host "Stack: $StackName | Region: $Region" -ForegroundColor Yellow
Write-Host

# Get stack resources
Write-Host "1. Getting stack resources..." -ForegroundColor Green
$Resources = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" cloudformation describe-stack-resources --stack-name $StackName --region $Region | ConvertFrom-Json

$TargetGroupArn = ($Resources.StackResources | Where-Object {$_.LogicalResourceId -eq "TargetGroup"}).PhysicalResourceId
$ALBArn = ($Resources.StackResources | Where-Object {$_.LogicalResourceId -eq "ALB"}).PhysicalResourceId
$EC2InstanceId = ($Resources.StackResources | Where-Object {$_.LogicalResourceId -eq "EC2Instance"}).PhysicalResourceId
$SpotFleetId = ($Resources.StackResources | Where-Object {$_.LogicalResourceId -eq "SpotFleetRequest"}).PhysicalResourceId

Write-Host "Target Group ARN: $TargetGroupArn" -ForegroundColor White
Write-Host "ALB ARN: $ALBArn" -ForegroundColor White
Write-Host "EC2 Instance ID: $EC2InstanceId" -ForegroundColor White
Write-Host "Spot Fleet ID: $SpotFleetId" -ForegroundColor White
Write-Host

# Check target group health
Write-Host "2. Checking target group health..." -ForegroundColor Green
$TargetHealth = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" elbv2 describe-target-health --target-group-arn $TargetGroupArn --region $Region | ConvertFrom-Json

if ($TargetHealth.TargetHealthDescriptions.Count -eq 0) {
    Write-Host "❌ NO TARGETS REGISTERED!" -ForegroundColor Red
    Write-Host "This is likely the cause of the 503 error." -ForegroundColor Yellow
} else {
    foreach ($target in $TargetHealth.TargetHealthDescriptions) {
        $status = $target.TargetHealth.State
        $reason = $target.TargetHealth.Reason
        $description = $target.TargetHealth.Description
        
        if ($status -eq "healthy") {
            Write-Host "✅ Target: $($target.Target.Id) - Status: $status" -ForegroundColor Green
        } else {
            Write-Host "❌ Target: $($target.Target.Id) - Status: $status" -ForegroundColor Red
            Write-Host "   Reason: $reason" -ForegroundColor Yellow
            Write-Host "   Description: $description" -ForegroundColor Yellow
        }
    }
}
Write-Host

# Get running instances
Write-Host "3. Checking running instances..." -ForegroundColor Green
if ($EC2InstanceId) {
    Write-Host "On-demand instance: $EC2InstanceId" -ForegroundColor White
    $InstanceState = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" ec2 describe-instances --instance-ids $EC2InstanceId --region $Region --query "Reservations[0].Instances[0].State.Name" --output text
    Write-Host "   State: $InstanceState" -ForegroundColor $(if ($InstanceState -eq "running") {"Green"} else {"Yellow"})
}

if ($SpotFleetId) {
    Write-Host "Spot fleet: $SpotFleetId" -ForegroundColor White
    $SpotInstances = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" ec2 describe-spot-fleet-instances --spot-fleet-request-id $SpotFleetId --region $Region | ConvertFrom-Json
    
    if ($SpotInstances.ActiveInstances.Count -eq 0) {
        Write-Host "   ❌ No active spot instances!" -ForegroundColor Red
    } else {
        foreach ($instance in $SpotInstances.ActiveInstances) {
            Write-Host "   Instance: $($instance.InstanceId)" -ForegroundColor White
        }
    }
}
Write-Host

# Test ALB endpoint
Write-Host "4. Testing ALB endpoint..." -ForegroundColor Green
$ALBDns = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" elbv2 describe-load-balancers --load-balancer-arns $ALBArn --region $Region --query "LoadBalancers[0].DNSName" --output text

Write-Host "ALB DNS: $ALBDns" -ForegroundColor White
try {
    $Response = Invoke-WebRequest -Uri "http://$ALBDns/health" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Health endpoint response: $($Response.StatusCode)" -ForegroundColor Green
    Write-Host "   Content: $($Response.Content)" -ForegroundColor White
} catch {
    Write-Host "❌ Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "   Status Code: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
    }
}
Write-Host

Write-Host "=== Diagnostic Complete ===" -ForegroundColor Cyan
