# Remote Management System for Client Accounts

This guide explains how to use the remote management system to easily manage resources across all client accounts.

## Overview

The remote management system consists of:

1. **RobertRemoteManagementRole** - Created in each client account
2. **RobertClientManagementRole** - Created in the management account
3. **Remote Management Script** - Easy command-line interface

## Architecture

```
Management Account (228480945348)
├── RobertClientManagementRole
└── Remote Management Script

Client Account (737915157697 - Bailey Lessons)
├── RobertRemoteManagementRole
└── Client Infrastructure

Future Client Accounts
├── RobertRemoteManagementRole
└── Client Infrastructure
```

## Roles and Permissions

### RobertRemoteManagementRole (Client Accounts)
- **Purpose**: Allows management account to manage client resources
- **Permissions**: AdministratorAccess + additional management policies
- **Trust Policy**: Management account root with External ID
- **External ID**: `robert-consulting-remote-management`

### RobertClientManagementRole (Management Account)
- **Purpose**: Allows terraform-user to assume client roles
- **Permissions**: Organizations, billing, security, support access
- **Trust Policy**: terraform-user

## Usage

### 1. List Available Clients

```bash
cd terraform
bash scripts/remote-management.sh list
```

### 2. Assume Remote Management Role

```bash
# Assume role for a specific client
bash scripts/remote-management.sh assume baileylessons

# Start a shell with client credentials
bash scripts/remote-management.sh shell baileylessons

# Execute a command in client context
bash scripts/remote-management.sh exec baileylessons "aws s3 ls"
```

### 3. Using the Remote Management Role

Once you've assumed the role, you can:

```bash
# List S3 buckets
aws s3 ls

# Check CloudFront distributions
aws cloudfront list-distributions

# View CloudWatch metrics
aws cloudwatch list-metrics

# Check Route 53 hosted zones
aws route53 list-hosted-zones

# View security findings
aws securityhub get-findings
```

## Adding New Clients

### 1. Update the Remote Management Script

Edit `terraform/scripts/remote-management.sh`:

```bash
# Add to get_client_account function
"newclient")
    echo "123456789012"
    ;;

# Add to get_all_clients function
echo "newclient"
```

### 2. Deploy Client Infrastructure

```bash
cd terraform/clients/newclient
terraform init
terraform plan -var="client_account_id=123456789012"
terraform apply
```

### 3. Test Remote Access

```bash
bash scripts/remote-management.sh assume newclient
```

## Security Features

### External ID Protection
- All role assumptions require External ID: `robert-consulting-remote-management`
- Prevents unauthorized role assumption

### Least Privilege Access
- Management role has specific permissions for client management
- Client roles have full access only within their account

### Audit Trail
- All role assumptions are logged in CloudTrail
- Session names include client name for easy tracking

## Troubleshooting

### Common Issues

1. **"Cannot assume role" error**
   - Check if the role exists in the client account
   - Verify External ID is correct
   - Ensure management account has assume role permissions

2. **"Access denied" errors**
   - Verify you're using the correct role
   - Check if the role has the required permissions
   - Ensure the client account is properly configured

3. **Script compatibility issues**
   - Use `bash scripts/remote-management.sh` instead of `./scripts/remote-management.sh`
   - Ensure you're using bash 3.2+ (macOS default)

### Debugging

```bash
# Check current AWS identity
aws sts get-caller-identity

# List available roles in client account
aws iam list-roles --query 'Roles[?contains(RoleName, `Robert`)]'

# Test role assumption manually
aws sts assume-role \
  --role-arn "arn:aws:iam::737915157697:role/RobertRemoteManagementRole" \
  --role-session-name "test-session" \
  --external-id "robert-consulting-remote-management"
```

## Best Practices

1. **Use the script for all client access** - Don't manually assume roles
2. **Always use External ID** - Never assume roles without it
3. **Monitor role usage** - Check CloudTrail for unusual activity
4. **Rotate credentials regularly** - Update External IDs periodically
5. **Use least privilege** - Only assume roles when necessary

## Future Enhancements

- [ ] Add support for multiple External IDs per client
- [ ] Implement role session duration limits
- [ ] Add automated credential rotation
- [ ] Create web interface for role management
- [ ] Add support for temporary credentials
- [ ] Implement cross-account resource discovery
