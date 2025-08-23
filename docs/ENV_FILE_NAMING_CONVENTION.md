# Environment File Naming Convention

This document outlines the naming convention for environment files in this repository to ensure proper separation between configuration templates and actual configuration files containing sensitive information.

## Naming Convention

### Template Files (Tracked by Git) ✅
These files contain example configurations and should be committed to the repository:

- `.env.example` - Main configuration template
- `.env.local.example` - Local development template
- `.env.staging.example` - Staging environment template  
- `.env.production.example` - Production environment template
- `config.env.example` - Alternative naming for specific configs
- Any file matching the pattern `*example*` with `.env` extension

### Configuration Files (Ignored by Git) ❌
These files contain actual configuration values including secrets and should NOT be committed:

- `.env` - Main environment configuration
- `.env.local` - Local development configuration
- `.env.staging` - Staging environment configuration
- `.env.production` - Production environment configuration
- `.env.test` - Test environment configuration

## Best Practices

### For Template Files
1. **Include all required variables** with placeholder values
2. **Document each variable** with comments explaining its purpose
3. **Use safe default values** where possible
4. **Include examples** for complex configurations
5. **Group related variables** with section headers

Example:
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_username
DB_PASSWORD=your_secure_password

# API Keys (obtain from service provider)
API_KEY=your_api_key_here
JWT_SECRET=your_jwt_secret_here
```

### For Actual Configuration Files
1. **Copy from template** using: `cp .env.example .env`
2. **Replace placeholder values** with actual configuration
3. **Never commit** these files to version control
4. **Use strong passwords and keys** for production
5. **Rotate secrets regularly** in production environments

## Git Configuration

The `.gitignore` file is configured to:
- ✅ **Allow** files containing "example" in the name
- ❌ **Block** actual configuration files
- 🔒 **Protect** sensitive information from accidental commits

## Verification

To verify a file will be tracked/ignored by git:
```bash
# Check if a file would be ignored (exit code 0 = ignored, 1 = tracked)
git check-ignore filename

# Example outputs:
git check-ignore .env.example          # Exit code 1 (tracked) ✅
git check-ignore .env                  # Exit code 0 (ignored) ✅ 
git check-ignore .env.local.example    # Exit code 1 (tracked) ✅
git check-ignore .env.production       # Exit code 0 (ignored) ✅
```

## Migration Guide

If you have existing environment files that don't follow this convention:

1. **Backup** your current configuration files
2. **Rename** template files to include "example"
3. **Copy** templates to create new configuration files
4. **Update** your documentation and deployment scripts
5. **Test** that the new files work correctly

## Security Notes

- 🚨 **Never commit actual API keys, passwords, or tokens**
- 🔍 **Review commits** before pushing to ensure no secrets are included
- 🔄 **Rotate secrets** if accidentally committed
- 📝 **Use environment variable injection** in CI/CD pipelines
- 🛡️ **Consider using secret management tools** for production