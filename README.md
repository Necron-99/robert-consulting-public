# Robert Consulting Website

A professional consulting business website built with modern web technologies and deployed on AWS using Terraform with GitHub Actions.

## 🚀 Features

- **Responsive Design**: Mobile-first approach with modern UI/UX
- **Professional Services**: Comprehensive service offerings display
- **Contact Integration**: Interactive contact form with validation
- **Performance Optimized**: Fast loading with CloudFront CDN
- **SEO Ready**: Optimized for search engines
- **Secure**: HTTPS enabled with AWS security best practices
- **CI/CD**: Automated deployment with GitHub Actions

## 🏗️ Infrastructure

This project uses Terraform to provision AWS infrastructure:

- **S3 Bucket**: Static website hosting
- **CloudFront**: Global CDN for fast content delivery
- **Route 53**: DNS management (optional)
- **ACM**: SSL/TLS certificates

## 📁 Project Structure

```
├── .github/workflows/     # GitHub Actions workflows
│   └── deploy.yml         # CI/CD pipeline configuration
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Terraform outputs
│   ├── versions.tf        # Provider versions
│   └── terraform.tfvars.example # Example variables file
├── website/               # Website source files
│   ├── index.html         # Main website page
│   ├── styles.css         # CSS styles
│   ├── script.js          # JavaScript functionality
│   └── error.html         # 404 error page
└── README.md              # Project documentation
```

## 🛠️ Setup Instructions

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- GitHub account with Actions enabled

### 1. Clone and Configure

```bash
git clone <your-github-repo-url>
cd robert-consulting-website
```

### 2. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Initialize and Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Configure GitHub Secrets

In your GitHub repository settings, go to Secrets and variables → Actions, and add these secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## 🔄 CI/CD Pipeline

The GitHub Actions workflow includes:

1. **Validate**: Terraform validation and formatting
2. **Plan**: Infrastructure planning
3. **Apply**: Infrastructure deployment (automatic on main branch)
4. **Deploy**: Website deployment to S3 with CloudFront invalidation

## 🌐 Deployment

The website is automatically deployed when changes are pushed to the main branch:

1. Infrastructure is provisioned/updated with Terraform
2. Website files are synced to S3
3. CloudFront cache is invalidated
4. Website is live at the CloudFront URL

## 📝 Customization

### Website Content

Edit the files in the `website/` directory:

- `index.html`: Main page content and structure
- `styles.css`: Styling and responsive design
- `script.js`: Interactive functionality
- `error.html`: Custom 404 page

### Infrastructure

Modify `terraform/main.tf` to:

- Add additional AWS resources
- Configure custom domains
- Set up monitoring and logging
- Add security enhancements

## 🔒 Security

- S3 bucket configured for public read access
- CloudFront provides HTTPS encryption
- Origin Access Identity for secure S3 access
- No sensitive data in version control

## 📊 Monitoring

Consider adding:

- CloudWatch metrics for performance monitoring
- S3 access logging
- CloudFront analytics
- Uptime monitoring

## 🚀 Performance

- CloudFront CDN for global content delivery
- Gzip compression enabled
- Optimized images and assets
- Minimal JavaScript and CSS

## 📞 Support

For questions or issues:

- Email: robert@robertconsulting.net
- Create an issue in the GitHub repository

## 📄 License

© 2024 Robert Consulting. All rights reserved.

---

**Built with ❤️ using Terraform, AWS, and modern web technologies.**
