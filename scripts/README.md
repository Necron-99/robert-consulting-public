# Scripts Directory

This directory contains all automation scripts organized by purpose.

## Directory Structure

### `/deployment/`
- **Site Deployment**: Scripts for deploying websites to S3 and CloudFront
- **Environment Setup**: Scripts for setting up staging and production environments
- **Infrastructure Deployment**: Terraform and AWS infrastructure deployment scripts

### `/security/`
- **Security Scanning**: Scripts for running security scans and vulnerability assessments
- **WAF Management**: Scripts for managing Web Application Firewall rules
- **Access Control**: Scripts for managing authentication and authorization

### `/maintenance/`
- **Cleanup Scripts**: Scripts for cleaning up unused resources
- **Backup Scripts**: Scripts for backing up configurations and data
- **Update Scripts**: Scripts for updating dependencies and configurations

### `/utilities/`
- **General Utilities**: General-purpose utility scripts
- **Diagnostic Scripts**: Scripts for diagnosing issues and troubleshooting
- **Configuration Scripts**: Scripts for managing various configurations

## Script Categories

### Deployment Scripts
- `deploy-admin-site.sh` - Deploy admin site to S3
- `deploy-staging-environment.sh` - Deploy staging environment
- `deploy-client-content.sh` - Deploy client content

### Security Scripts
- `security-scan.sh` - Run comprehensive security scan
- `security-scan.ps1` - PowerShell version of security scan
- `enable-waf-protection.sh` - Enable WAF protection
- `disable-waf-protection.sh` - Disable WAF protection

### Maintenance Scripts
- `cleanup-unused-infrastructure.sh` - Clean up unused AWS resources
- `cleanup-unused-infrastructure-fixed.sh` - Improved cleanup script

### Utility Scripts
- `setup-github-environment.sh` - Set up GitHub environment
- `setup-github-credentials.sh` - Configure GitHub credentials
- `analyze-github-actions-ips.sh` - Analyze GitHub Actions IP ranges

## Usage

All scripts are designed to be run from the project root directory:

```bash
# Example usage
./scripts/deployment/deploy-admin-site.sh
./scripts/security/security-scan.sh
./scripts/maintenance/cleanup-unused-infrastructure.sh
```

## Script Requirements

- **Bash Scripts**: Require bash shell and AWS CLI
- **PowerShell Scripts**: Require PowerShell and AWS CLI
- **Terraform Scripts**: Require Terraform and AWS credentials

## Security Notes

- Scripts may contain sensitive configuration - review before execution
- Some scripts require AWS credentials and appropriate permissions
- Always test scripts in a non-production environment first

## Contributing

When adding new scripts:
1. Place in the appropriate category directory
2. Add proper error handling and logging
3. Include usage documentation in script comments
4. Update this README with script description
