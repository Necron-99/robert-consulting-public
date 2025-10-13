# Bailey Lessons Repository Cleanup Plan

## Current State Analysis
Your existing baileylessons.com repository likely contains:
- Mixed infrastructure and content
- Terraform state files
- CI/CD workflows
- Documentation

## Cleanup Strategy

### Phase 1: Separate Infrastructure and Content

#### 1. Create New Infrastructure Repository
```bash
# Create new repo for infrastructure
gh repo create baileylessons-infrastructure --private

# Clone and setup
git clone https://github.com/your-org/baileylessons-infrastructure.git
cd baileylessons-infrastructure

# Copy template structure
cp -r /path/to/client-template/* .
```

#### 2. Migrate Infrastructure Code
```bash
# Copy infrastructure from current repo
cp -r /path/to/current/baileylessons/terraform/* infrastructure/

# Update configuration
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit with baileylessons-specific settings
```

#### 3. Clean Up Current Repository
```bash
# Remove infrastructure files
rm -rf terraform/
rm -rf .github/workflows/infrastructure-*
rm -rf docs/infrastructure/

# Keep only content
# - website/ (if exists)
# - content/
# - .github/workflows/content-*
# - README.md (update for content-only)
```

### Phase 2: Content Repository Structure

#### Recommended Structure for baileylessons.com:
```
baileylessons.com/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy-content.yml
├── content/
│   ├── website/
│   │   ├── index.html
│   │   ├── css/
│   │   ├── js/
│   │   └── assets/
│   └── deploy.sh
└── docs/
    ├── CONTENT_GUIDE.md
    └── DEPLOYMENT.md
```

### Phase 3: Migration Steps

#### 1. Infrastructure Migration
```bash
# In baileylessons-infrastructure repo
cd infrastructure

# Configure client settings
cat > terraform.tfvars << EOF
client_name        = "baileylessons"
client_domain      = "baileylessons.com"
client_account_id  = "737915157697"
aws_region         = "us-east-1"
environment        = "production"

additional_domains = [
  "www.baileylessons.com",
  "app.baileylessons.com"
]

# Adopt existing resources
existing_cloudfront_distribution_id = "E23X7BS3VXFFFZ"
existing_route53_zone_id            = "Z01009052GCOJI1M2TTF7"
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:737915157697:certificate/443ea37e-fb03-4993-8e65-f7a10d25e32e"

enable_cloudfront  = true
enable_waf         = true
enable_monitoring  = true
EOF

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

#### 2. Content Migration
```bash
# In baileylessons.com repo
mkdir -p content/website

# Move website content
mv website/* content/website/ 2>/dev/null || true
mv public/* content/website/ 2>/dev/null || true
mv src/* content/website/ 2>/dev/null || true

# Update deploy script
cp client-template/content/deploy.sh content/
chmod +x content/deploy.sh
```

#### 3. Update CI/CD
```bash
# Remove infrastructure workflows
rm .github/workflows/terraform-*
rm .github/workflows/infrastructure-*

# Add content deployment workflow
cp client-template/.github/workflows/deploy-content.yml .github/workflows/
```

### Phase 4: Repository Cleanup

#### Files to Remove from baileylessons.com:
- `terraform/` (entire directory)
- `.terraform/` (if exists)
- `terraform.tfstate*`
- `*.tfplan`
- Infrastructure documentation
- Terraform-related CI/CD workflows

#### Files to Keep in baileylessons.com:
- Website content (`content/website/`)
- Content deployment scripts
- Content-specific documentation
- Content deployment CI/CD

#### Files to Add to baileylessons.com:
- Updated README.md for content-only repo
- Content deployment guide
- Content-specific workflows

### Phase 5: Documentation Updates

#### Update baileylessons.com README.md:
```markdown
# Bailey Lessons Website

This repository contains the website content for baileylessons.com.

## Repository Structure
- `content/website/` - Website files (HTML, CSS, JS, assets)
- `content/deploy.sh` - Deployment script
- `.github/workflows/` - CI/CD automation

## Deployment
Content is automatically deployed via GitHub Actions when changes are pushed.

## Infrastructure
Infrastructure is managed in a separate repository: `baileylessons-infrastructure`
```

#### Update Infrastructure Repository README.md:
```markdown
# Bailey Lessons Infrastructure

This repository manages the AWS infrastructure for baileylessons.com.

## Repository Structure
- `infrastructure/` - Terraform infrastructure code
- `.github/workflows/` - CI/CD automation
- `docs/` - Infrastructure documentation

## Deployment
Infrastructure is deployed via Terraform and GitHub Actions.
```

### Phase 6: Testing and Validation

#### 1. Test Infrastructure Deployment
```bash
cd baileylessons-infrastructure/infrastructure
terraform plan
terraform apply
```

#### 2. Test Content Deployment
```bash
cd baileylessons.com/content
./deploy.sh
```

#### 3. Verify Website
- Check https://baileylessons.com
- Verify CloudFront distribution
- Check DNS resolution
- Test all pages and functionality

### Phase 7: Final Cleanup

#### 1. Remove Old Files
```bash
# In baileylessons.com repo
rm -rf terraform/
rm -rf .terraform/
rm -f terraform.tfstate*
rm -f *.tfplan
rm -f .github/workflows/terraform-*
```

#### 2. Update .gitignore
```bash
# Remove Terraform entries
# Keep content-related entries
```

#### 3. Commit Changes
```bash
git add .
git commit -m "Separate infrastructure and content repositories"
git push origin main
```

## Benefits of Separation

### Infrastructure Repository
- **Focused**: Only infrastructure concerns
- **Secure**: Separate access controls
- **Scalable**: Easy to add new clients
- **Maintainable**: Clear separation of concerns

### Content Repository
- **Simple**: Only content and deployment
- **Fast**: Quick content updates
- **Independent**: No infrastructure dependencies
- **Collaborative**: Easy for content creators

## Next Steps

1. **Create infrastructure repository** using the template
2. **Migrate infrastructure code** from current repo
3. **Clean up current repository** to content-only
4. **Test both deployments** thoroughly
5. **Update documentation** and workflows
6. **Train team** on new structure

## Support

- **Infrastructure issues**: Check `baileylessons-infrastructure` repository
- **Content issues**: Check `baileylessons.com` repository
- **General questions**: Contact Robert Consulting
