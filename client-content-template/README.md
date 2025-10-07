# [CLIENT_NAME] Content

This repository contains the website content for [CLIENT_NAME].

## Repository Structure

```
├── content/          # Website content and assets
├── .github/workflows/ # CI/CD automation
└── docs/            # Documentation
```

## Quick Start

### Prerequisites
- AWS CLI configured with deployment credentials
- GitHub repository with required secrets
- Infrastructure deployed (managed by main repo)

### Content Deployment
```bash
# Deploy website content
cd content
./deploy.sh
```

### Automated Deployment
Content is automatically deployed via GitHub Actions when:
- Changes are pushed to the `content/` directory
- Workflow is manually triggered

## Configuration

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

## Deployment

### Manual Deployment
```bash
cd content
./deploy.sh
```

### Automated Deployment
- **Trigger**: Push to main branch
- **Process**: Sync content to S3 → invalidate CloudFront
- **Status**: Check GitHub Actions tab

## Monitoring

- **Performance**: CloudFront metrics and dashboards
- **Cost**: S3 storage and CloudFront usage costs
- **Errors**: 4xx/5xx error tracking and alerts
- **Cache**: CloudFront cache hit rates and performance

## Infrastructure

Infrastructure is managed in the main repository:
- **S3 bucket**: Website hosting
- **CloudFront**: CDN and caching
- **Route53**: DNS management
- **SSL**: Certificate management
- **WAF**: Security and protection

## Support

- **Content issues**: Create GitHub issues in this repository
- **Infrastructure issues**: Contact main repository
- **Deployment problems**: Check GitHub Actions logs
- **Contact**: [YOUR_CONTACT_INFO]

## License

[LICENSE_INFO]
