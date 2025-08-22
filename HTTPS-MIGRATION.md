# WWIZ HTTPS Migration

## Overview
This repository now includes complete HTTPS infrastructure for the WWIZ frontend. The solution provides the quickest and lowest impact migration from HTTP port 80 to HTTPS.

## What's Included

### Core Infrastructure
- **docker-compose.yml**: Orchestrates AnythingLLM, Nginx reverse proxy, and Certbot
- **nginx/nginx.conf**: Production-ready Nginx configuration with HTTPS
- **SSL Certificate Management**: Automated Let's Encrypt integration

### Deployment Scripts
- **setup-https.sh**: Quick setup with self-signed certificates for development
- **scripts/get-letsencrypt-cert.sh**: Production SSL certificate from Let's Encrypt
- **scripts/health-check.sh**: Validates HTTPS deployment
- **deploy.sh**: Interactive deployment wizard

### Configuration
- **.env.example**: Environment configuration template
- **.gitignore**: Protects sensitive files and certificates

## Quick Start

1. **Development Setup**:
   ```bash
   ./setup-https.sh
   ```

2. **Production Setup**:
   ```bash
   DOMAIN=your-domain.com EMAIL=your-email@example.com ./scripts/get-letsencrypt-cert.sh
   ```

3. **Interactive Deployment**:
   ```bash
   ./deploy.sh
   ```

## Security Features

- **Automatic HTTP to HTTPS redirect**: All HTTP traffic redirects to HTTPS
- **Modern TLS**: Supports TLS 1.2 and 1.3 with secure cipher suites
- **Security Headers**: HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Certificate Auto-renewal**: Automatic renewal via Certbot container
- **OCSP Stapling**: Improved SSL performance and security

## Architecture

```
Internet → Nginx (Port 443) → AnythingLLM (Port 3001)
    ↓
HTTP (Port 80) redirects to HTTPS
```

## Files Added

```
├── docker-compose.yml          # Container orchestration
├── nginx/
│   └── nginx.conf             # Nginx HTTPS configuration
├── scripts/
│   ├── get-letsencrypt-cert.sh # Production SSL setup
│   └── health-check.sh        # Deployment validation
├── setup-https.sh             # Development setup
├── deploy.sh                  # Interactive deployment
├── .env.example               # Configuration template
└── .gitignore                 # Security exclusions
```

This solution ensures zero downtime migration and provides a production-ready HTTPS infrastructure for the WWIZ application.