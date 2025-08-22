#!/usr/bin/env powershell
# Quick and dirty CloudFormation stack update script

$StackName = "ai-poc-anythingllm"
$Region = "ap-southeast-2"
$TemplateFile = "wwiz-cloudformation.yaml"

Write-Host "Updating CloudFormation stack: $StackName" -ForegroundColor Green
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Template: $TemplateFile" -ForegroundColor Yellow

# Check if template file exists
if (-not (Test-Path $TemplateFile)) {
    Write-Host "Template file not found: $TemplateFile" -ForegroundColor Red
    exit 1
}

try {
    # Update the stack
    & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" cloudformation update-stack `
        --stack-name $StackName `
        --template-body "file://$TemplateFile" `
        --capabilities CAPABILITY_IAM `
        --region $Region

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Stack update initiated successfully!" -ForegroundColor Green
        Write-Host "Monitor progress at: https://ap-southeast-2.console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks" -ForegroundColor Cyan
    } else {
        Write-Host "Stack update failed!" -ForegroundColor Red
    }
} catch {
    Write-Host "Error updating stack: $($_.Exception.Message)" -ForegroundColor Red
}
