# Bailey Lessons Content Repository Cleanup Plan

## Current State Analysis
Your existing baileylessons.com repository likely contains:
- Mixed infrastructure and content
- Terraform state files
- CI/CD workflows
- Documentation

## Cleanup Strategy

### Phase 1: Separate Content from Infrastructure

#### 1. Create New Content Repository
```bash
# Create new repo for content only
gh repo create baileylessons-content --private

# Clone and setup
git clone https://github.com/your-org/baileylessons-content.git
cd baileylessons-content

# Copy template structure
cp -r /path/to/client-content-template/* .
```

#### 2. Migrate Content
```bash
# Copy website content from current repo
cp -r /path/to/current/baileylessons/website/* content/website/ 2>/dev/null || true
cp -r /path/to/current/baileylessons/public/* content/website/ 2>/dev/null || true
cp -r /path/to/current/baileylessons/src/* content/website/ 2>/dev/null || true

# Update deploy script
cp client-content-template/content/deploy.sh content/
chmod +x content/deploy.sh
```

#### 3. Clean Up Current Repository
```bash
# Remove content files (keep infrastructure)
rm -rf website/
rm -rf public/
rm -rf src/
rm -rf content/

# Keep infrastructure files
# - terraform/
# - .github/workflows/terraform-*
# - Infrastructure documentation
```

### Phase 2: Content Repository Structure

#### Recommended Structure for baileylessons-content:
```
baileylessons-content/
├── README.md
├── .gitignore
├── .github/
│   └── workflows/
│       ├── deploy-content.yml
│       └── validate-content.yml
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

#### 1. Content Migration
```bash
# In baileylessons-content repo
mkdir -p content/website

# Copy website content
cp -r /path/to/current/baileylessons/website/* content/website/ 2>/dev/null || true
cp -r /path/to/current/baileylessons/public/* content/website/ 2>/dev/null || true
cp -r /path/to/current/baileylessons/src/* content/website/ 2>/dev/null || true

# Update deploy script
cp client-content-template/content/deploy.sh content/
chmod +x content/deploy.sh
```

#### 2. Update CI/CD
```bash
# Add content deployment workflow
cp client-content-template/.github/workflows/deploy-content.yml .github/workflows/
cp client-content-template/.github/workflows/validate-content.yml .github/workflows/
```

#### 3. Configure GitHub Secrets
```bash
# Required secrets in baileylessons-content repo:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - CLIENT_NAME: baileylessons
# - CLIENT_DOMAIN: baileylessons.com
```

### Phase 4: Repository Cleanup

#### Files to Remove from baileylessons.com:
- `website/` (entire directory)
- `public/` (if exists)
- `src/` (if exists)
- `content/` (if exists)
- Content-related CI/CD workflows
- Content-related documentation

#### Files to Keep in baileylessons.com:
- `terraform/` (entire directory)
- Infrastructure CI/CD workflows
- Infrastructure documentation
- Terraform state files

#### Files to Add to baileylessons-content:
- Updated README.md for content-only repo
- Content deployment guide
- Content-specific workflows

### Phase 5: Documentation Updates

#### Update baileylessons-content README.md:
```markdown
# Bailey Lessons Website Content

This repository contains the website content for baileylessons.com.

## Repository Structure
- `content/website/` - Website files (HTML, CSS, JS, assets)
- `content/deploy.sh` - Deployment script
- `.github/workflows/` - CI/CD automation

## Deployment
Content is automatically deployed via GitHub Actions when changes are pushed.

## Infrastructure
Infrastructure is managed in the main repository: `robert-consulting.net`
```

#### Update baileylessons.com README.md:
```markdown
# Bailey Lessons Infrastructure

This repository manages the AWS infrastructure for baileylessons.com.

## Repository Structure
- `terraform/` - Terraform infrastructure code
- `.github/workflows/` - CI/CD automation
- `docs/` - Infrastructure documentation

## Deployment
Infrastructure is deployed via Terraform and GitHub Actions.

## Content
Website content is managed in a separate repository: `baileylessons-content`
```

### Phase 6: Testing and Validation

#### 1. Test Content Deployment
```bash
cd baileylessons-content/content
./deploy.sh
```

#### 2. Test Infrastructure Deployment
```bash
cd baileylessons.com/terraform
terraform plan
terraform apply
```

#### 3. Verify Website
- Check https://baileylessons.com
- Verify CloudFront distribution
- Check DNS resolution
- Test all pages and functionality

### Phase 7: Final Cleanup

#### 1. Remove Content Files
```bash
# In baileylessons.com repo
rm -rf website/
rm -rf public/
rm -rf src/
rm -rf content/
rm -f .github/workflows/content-*
```

#### 2. Update .gitignore
```bash
# Remove content-related entries
# Keep infrastructure-related entries
```

#### 3. Commit Changes
```bash
git add .
git commit -m "Separate content and infrastructure repositories"
git push origin main
```

## Benefits of Separation

### Content Repository
- **Focused**: Only content concerns
- **Simple**: Easy content updates
- **Fast**: Quick deployment
- **Collaborative**: Easy for content creators

### Infrastructure Repository
- **Centralized**: All infrastructure in main repo
- **Secure**: Controlled access to infrastructure
- **Maintainable**: Clear separation of concerns
- **Scalable**: Easy to add new clients

## Next Steps

1. **Create content repository** using the template
2. **Migrate content** from current repo
3. **Clean up current repository** to infrastructure-only
4. **Test both deployments** thoroughly
5. **Update documentation** and workflows
6. **Train team** on new structure

## Support

- **Content issues**: Check `baileylessons-content` repository
- **Infrastructure issues**: Check main `robert-consulting.net` repository
- **General questions**: Contact Robert Consulting
