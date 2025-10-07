# Client Content Repository Template

## Repository Structure

```
client-name-content/
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

## Key Features

### Content Management
- **Website files**: HTML, CSS, JS, images, assets
- **Automated deployment**: GitHub Actions for content updates
- **CloudFront integration**: Automatic cache invalidation
- **Version control**: Full history of content changes

### Deployment Process
- **Trigger**: Push to main branch or manual trigger
- **Process**: Sync content to S3 → invalidate CloudFront
- **Frequency**: Can be automated for content updates
- **Rollback**: Easy rollback via git history

### Infrastructure Integration
- **S3 bucket**: Managed by main infrastructure repo
- **CloudFront**: Managed by main infrastructure repo
- **DNS**: Managed by main infrastructure repo
- **SSL**: Managed by main infrastructure repo

## Setup Instructions

### 1. Repository Creation
```bash
# Create new repository
gh repo create client-name-content --private

# Clone and initialize
git clone https://github.com/your-org/client-name-content.git
cd client-name-content
```

### 2. Content Setup
```bash
# Create content structure
mkdir -p content/website/{css,js,assets}

# Add website files
# Copy existing website content to content/website/
```

### 3. CI/CD Configuration
```bash
# Copy GitHub Actions workflows
cp -r .github/workflows/* .github/workflows/

# Configure secrets in GitHub repository:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - CLIENT_NAME
# - CLIENT_DOMAIN
```

## Client-Specific Configuration

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID`: AWS credentials for deployment
- `AWS_SECRET_ACCESS_KEY`: AWS credentials for deployment
- `CLIENT_NAME`: Client name (for SSM parameters)
- `CLIENT_DOMAIN`: Client domain name

### Content Structure
```
content/website/
├── index.html          # Main page
├── about.html          # About page
├── contact.html        # Contact page
├── css/
│   ├── style.css       # Main stylesheet
│   └── responsive.css   # Responsive styles
├── js/
│   ├── main.js         # Main JavaScript
│   └── contact.js      # Contact form handling
└── assets/
    ├── images/         # Images and graphics
    ├── icons/          # Favicons and icons
    └── fonts/          # Custom fonts
```

## Deployment Workflows

### Content Deployment
- **Trigger**: Push to main branch
- **Process**: Sync content to S3 → invalidate CloudFront
- **Frequency**: Automatic on content changes
- **Rollback**: Git-based rollback

### Content Validation
- **Trigger**: Pull requests
- **Process**: Validate HTML, CSS, JS
- **Tools**: HTML validation, CSS linting, JS linting
- **Reports**: Validation results in PR comments

## Integration with Main Infrastructure

### SSM Parameters (Set by Infrastructure)
- `/clients/[CLIENT_NAME]/s3-bucket` - S3 bucket name
- `/clients/[CLIENT_NAME]/cloudfront-distribution` - CloudFront distribution ID
- `/clients/[CLIENT_NAME]/domain` - Client domain name

### Deployment Process
1. **Content changes** pushed to repository
2. **GitHub Actions** triggered automatically
3. **AWS credentials** used to access SSM parameters
4. **S3 sync** uploads content to client bucket
5. **CloudFront invalidation** clears cache
6. **Deployment status** reported back

## Security Considerations

### Access Control
- **Repository access**: Private repositories only
- **AWS permissions**: Minimal S3 and CloudFront access
- **Content validation**: Automated security scanning

### Content Security
- **HTTPS enforcement**: Managed by infrastructure
- **Security headers**: Managed by infrastructure
- **WAF protection**: Managed by infrastructure

## Monitoring

### Content Metrics
- **Deployment frequency**: Track content update frequency
- **Page load times**: CloudFront performance metrics
- **Error rates**: 4xx/5xx error tracking
- **Cache hit rates**: CloudFront cache efficiency

### Cost Monitoring
- **S3 storage costs**: Content storage costs
- **CloudFront costs**: CDN usage costs
- **Data transfer**: Bandwidth usage
- **Request counts**: API call costs

## Troubleshooting

### Common Issues
1. **Deployment failures**: Check AWS credentials and permissions
2. **Cache issues**: Manual CloudFront invalidation
3. **Content not updating**: Check S3 sync and CloudFront
4. **DNS issues**: Verify domain configuration

### Recovery Procedures
1. **Content rollback**: Git-based rollback
2. **Deployment retry**: Manual workflow trigger
3. **Cache clearing**: Manual CloudFront invalidation
4. **Content restore**: S3 versioning restore

## Best Practices

### Content Management
- **Version control**: All content in git
- **Automated deployment**: CI/CD for all changes
- **Content validation**: Automated quality checks
- **Backup procedures**: Git-based backups

### Performance
- **Image optimization**: Compress images before commit
- **CSS/JS minification**: Minify assets for production
- **Cache optimization**: Proper cache headers
- **CDN usage**: Leverage CloudFront caching

### Security
- **Content scanning**: Automated security checks
- **Access control**: Private repositories
- **Audit logging**: Track all deployments
- **Vulnerability scanning**: Regular security scans
