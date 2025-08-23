# Environment File Naming Convention

This document explains the naming convention for environment files to separate configuration templates from actual configuration files containing sensitive information.

## What it is

Environment files with "example" in the name are tracked by git as templates, while actual configuration files are ignored to protect sensitive data.

## Why

This convention allows teams to share configuration templates while keeping actual secrets and environment-specific values secure and out of version control.

## Examples

**Template files (tracked by git):**
- `.env.example` - Main configuration template
- `.env.local.example` - Local development template
- `.env.production.example` - Production environment template

**Configuration files (ignored by git):**
- `.env` - Actual environment configuration with real values
- `.env.local` - Local development configuration
- `.env.production` - Production environment configuration

To use: Copy the template (`cp .env.example .env`) and replace placeholder values with your actual configuration.