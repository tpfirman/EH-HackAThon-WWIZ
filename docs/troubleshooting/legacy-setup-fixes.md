# Legacy Setup Script Fixes (Archived)

> **📅 Archived:** August 23, 2025  
> **Status:** Issues resolved in current version  
> **Purpose:** Historical reference for troubleshooting similar issues  

## Problem Summary

The `setup-ai-poc.sh` script was encountering multiple issues that prevented AnythingLLM from starting properly, yet it was reporting false success messages. The Docker image was never being pulled because the container was never actually created.

## Issues Identified and Fixed

### 1. UTF-8 BOM Causing Shebang Error

**Issue:** 
```
./infra/scripts/setup-ai-poc.sh: line 1: #!/bin/bash: No such file or directory
```

**Root Cause:** The script file contained a UTF-8 Byte Order Mark (BOM) at the beginning, which made the shell interpreter try to execute `﻿#!/bin/bash` (with invisible BOM character) instead of recognizing it as a proper shebang.

**Fix:** Removed the UTF-8 BOM from the beginning of the file using `sed -i '1s/^\xEF\xBB\xBF//'`.

### 2. Missing Log Functions in Generated Script

**Issue:** 
```
/home/ec2-user/setup-anythingllm.sh: line 50: log_step: command not found
/home/ec2-user/setup-anythingllm.sh: line 52: log_error: command not found
```

**Root Cause:** The main script generates a separate `setup-anythingllm.sh` script that uses logging functions (`log_step`, `log_error`, `log_success`, etc.) but doesn't define them. These functions were only defined in the parent script.

**Fix:** Added all required logging functions to the generated script with proper color definitions and log file handling.

### 3. Poor Error Handling - False Success Messages

**Issue:** The script was reporting "SUCCESS: AnythingLLM setup completed successfully" even when the container failed to start.

**Root Cause:** 
- The script didn't validate that Docker Compose commands actually succeeded
- Container status checks were using warnings instead of errors
- No validation that containers were actually running vs. just created

**Fix:** 
- Added proper error checking for Docker Compose operations
- Changed container validation to require "running" status, not just existence
- Added proper exit codes when containers fail to start
- Enhanced diagnostics with detailed container logs when failures occur

### 4. Container Not Starting - No Image Pull

**Issue:** `Error response from daemon: No such container: anythingllm` because the container was never created.

**Root Cause:** Docker Compose commands were failing silently, but the script continued execution and reported success.

**Fix:** 
- Added validation that Docker Compose operations succeed before proceeding
- Added verification that containers are actually running before reporting success
- Added proper error handling to fail fast when containers don't start

## Why Failures Weren't Being Flagged

The original script had several anti-patterns that masked failures:

1. **Ignored Exit Codes:** Docker Compose commands weren't checked for success
2. **Warnings Instead of Errors:** Critical failures were logged as warnings
3. **Continue on Failure:** The script used `|| true` and continued even after critical failures
4. **No Validation:** No checks to ensure containers actually started before reporting success
5. **Poor Diagnostics:** Limited information when things went wrong

## Validation

The fixes have been validated with comprehensive tests:

1. ✅ **Shebang Test:** Confirms UTF-8 BOM is removed
2. ✅ **Syntax Test:** Validates script syntax is correct
3. ✅ **Function Test:** Confirms all log functions are present in generated script
4. ✅ **Error Handling Test:** Validates improved error handling logic
5. ✅ **Container Validation Test:** Confirms proper container status checking
6. ✅ **Docker Compose Test:** Validates generated configuration is syntactically correct

## Expected Behavior After Fixes

The script will now:

1. **Execute without shebang errors** - BOM removed
2. **Report accurate status** - No false success messages
3. **Fail fast on errors** - Proper exit codes when containers don't start
4. **Provide better diagnostics** - Detailed logs when issues occur
5. **Actually validate container status** - Ensures AnythingLLM is running before proceeding

If the Docker image still doesn't pull or the container doesn't start, the script will now properly identify and report these issues instead of masking them.