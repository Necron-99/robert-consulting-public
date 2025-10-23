# Configuration Directory

This directory contains all configuration files organized by service and environment.

## Directory Structure

### `/terraform/`
- **Variable Files**: Terraform variable definitions (`.tfvars` files)
- **Environment Configs**: Environment-specific configurations

### `/aws/`
- **AWS Configurations**: AWS service configurations and settings
- **CloudFormation Templates**: Infrastructure templates (if any)

### `/github/`
- **GitHub Configurations**: GitHub-specific configuration files
- **Workflow Configs**: GitHub Actions workflow configurations

## File Types

### Terraform Configuration
- `*.tfvars` - Terraform variable files (sensitive data - not committed)
- `*.tfvars.example` - Example variable files (safe to commit)

### JSON Configuration
- `*.json` - JSON configuration files
- `package.json` - Node.js package configuration
- `tsconfig.json` - TypeScript configuration

### Other Configuration
- `*.conf` - General configuration files
- `*.yaml` / `*.yml` - YAML configuration files
- `*.toml` - TOML configuration files

## Security Notes

⚠️ **IMPORTANT**: This directory may contain sensitive configuration data.

### Files to NEVER Commit:
- `*.tfvars` - Contains sensitive variables
- `credentials.json` - Contains API keys and secrets
- `config.json` - May contain sensitive configuration
- `secrets.json` - Contains secrets and passwords

### Files Safe to Commit:
- `*.tfvars.example` - Example files with placeholder values
- `package.json` - Public package configuration
- `*.conf.example` - Example configuration files

## Usage

Configuration files are typically referenced by:
- **Terraform**: Uses `.tfvars` files for variable values
- **Scripts**: May reference JSON config files for settings
- **Applications**: Use configuration files for runtime settings

## Environment-Specific Configs

- **Development**: Local development configurations
- **Staging**: Staging environment configurations  
- **Production**: Production environment configurations

## Contributing

When adding configuration files:
1. Use `.example` suffix for template files
2. Never commit files with sensitive data
3. Document required variables in example files
4. Update this README with new configuration types
