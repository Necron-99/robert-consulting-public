# Bailey Lessons Educational Platform

This directory contains all content and infrastructure for the baileylessons.com educational platform.

## 📁 Directory Structure

```
baileylessons/
├── website/                 # Main website content
│   ├── css/                # Stylesheets
│   ├── js/                 # JavaScript files
│   ├── images/             # Images and logos
│   ├── blog-posts/         # Blog content
│   ├── pages/              # Additional pages
│   ├── index.html          # Homepage
│   └── ...
├── admin/                  # Admin panel
│   ├── css/                # Admin styles
│   ├── js/                 # Admin scripts
│   ├── images/             # Admin assets
│   └── index.html          # Admin dashboard
├── api/                    # API and backend
│   ├── lambda/             # AWS Lambda functions
│   └── functions/          # Serverless functions
├── assets/                 # Static assets
│   ├── uploads/            # User uploads
│   ├── backups/            # Backup files
│   └── logs/               # Log files
├── content/                # Educational content
│   ├── courses/            # Course materials
│   ├── lessons/            # Individual lessons
│   └── materials/          # Supporting materials
├── deployment/             # Deployment configurations
│   ├── staging/            # Staging environment
│   └── production/         # Production environment
├── infrastructure/         # Infrastructure as Code
│   ├── terraform/          # Terraform configurations
│   └── config/             # Configuration files
├── docs/                   # Documentation
│   ├── deployment/         # Deployment guides
│   ├── guides/             # User guides
│   └── api/                # API documentation
├── scripts/                # Automation scripts
│   ├── deploy/             # Deployment scripts
│   ├── backup/             # Backup scripts
│   └── maintenance/        # Maintenance scripts
└── s3-content/             # S3 bucket content (see below)
```

## 🚀 S3 Content Storage

### For S3 Bucket Files

Use the `s3-content/` directory to store files downloaded from S3 buckets:

```bash
# Download from S3 bucket
aws s3 sync s3://baileylessons-production-static ./s3-content/static/
aws s3 sync s3://baileylessons-production-uploads ./s3-content/uploads/
aws s3 sync s3://baileylessons-production-backups ./s3-content/backups/
aws s3 sync s3://baileylessons-production-logs ./s3-content/logs/
```

### S3 Content Structure

```
s3-content/
├── static/                 # Static website files
│   ├── css/
│   ├── js/
│   ├── images/
│   └── index.html
├── uploads/                # User uploaded content
├── backups/                # Backup files
└── logs/                   # Application logs
```

## 🔧 Development Workflow

### 1. Local Development
```bash
cd baileylessons/website
# Start local development server
python -m http.server 8000
# or
node server.js
```

### 2. Staging Deployment
```bash
cd baileylessons/scripts/deploy
./deploy-staging.sh
```

### 3. Production Deployment
```bash
cd baileylessons/scripts/deploy
./deploy-production.sh
```

## 📋 Current Status

- ✅ Directory structure created
- ✅ Mockup files moved to website/
- ✅ Logo SVG added to images/
- ⏳ S3 content sync pending
- ⏳ Infrastructure configuration pending
- ⏳ Deployment scripts pending

## 🎯 Next Steps

1. **Sync S3 Content**: Download current content from S3 buckets
2. **Configure Infrastructure**: Set up Terraform for baileylessons
3. **Create Deployment Scripts**: Automate staging/production deployments
4. **Update Content**: Integrate new logo and content
5. **Test Deployment**: Verify staging and production workflows

## 🔗 Related Files

- Infrastructure: `terraform/modules/baileylessons/`
- Deployment: `scripts/deploy-baileylessons.sh`
- Configuration: `config/baileylessons-*.json`
