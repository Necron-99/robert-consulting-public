#!/bin/bash

# Client Creation Script for Robert Consulting
# This script creates a new client infrastructure from the skeleton template

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKELETON_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLIENTS_DIR="$(dirname "$SKELETON_DIR")/clients"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage
show_usage() {
    echo "Usage: $0 -c <client-name> -e <environment> [options]"
    echo ""
    echo "Options:"
    echo "  -c, --client-name    Client name (required)"
    echo "  -e, --environment    Environment (production, staging, development)"
    echo "  -d, --domain         Domain name (optional)"
    echo "  -b, --budget         Monthly budget limit (default: 100)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -c acme-corp -e production"
    echo "  $0 -c acme-corp -e production -d acme-corp.com -b 200"
}

# Parse command line arguments
CLIENT_NAME=""
ENVIRONMENT=""
DOMAIN=""
BUDGET="100"

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--client-name)
            CLIENT_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -b|--budget)
            BUDGET="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$CLIENT_NAME" ]]; then
    log_error "Client name is required"
    show_usage
    exit 1
fi

if [[ -z "$ENVIRONMENT" ]]; then
    log_error "Environment is required"
    show_usage
    exit 1
fi

# Validate environment
case $ENVIRONMENT in
    production|staging|development)
        ;;
    *)
        log_error "Invalid environment: $ENVIRONMENT"
        log_error "Valid environments: production, staging, development"
        exit 1
        ;;
esac

# Set default domain if not provided
if [[ -z "$DOMAIN" ]]; then
    DOMAIN="${CLIENT_NAME}.com"
fi

# Functions
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is required but not installed. Aborting."; exit 1; }
    command -v aws >/dev/null 2>&1 || { log_error "AWS CLI is required but not installed. Aborting."; exit 1; }
    command -v jq >/dev/null 2>&1 || { log_error "jq is required but not installed. Aborting."; exit 1; }
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_client_directory() {
    log_info "Creating client directory structure..."
    
    # Create clients directory if it doesn't exist
    mkdir -p "$CLIENTS_DIR"
    
    # Create client directory
    CLIENT_DIR="$CLIENTS_DIR/$CLIENT_NAME"
    
    if [[ -d "$CLIENT_DIR" ]]; then
        log_error "Client directory already exists: $CLIENT_DIR"
        exit 1
    fi
    
    mkdir -p "$CLIENT_DIR"
    
    log_success "Client directory created: $CLIENT_DIR"
}

copy_skeleton_files() {
    log_info "Copying skeleton files..."
    
    # Copy Terraform files
    cp "$SKELETON_DIR/main.tf" "$CLIENT_DIR/"
    cp "$SKELETON_DIR/variables.tf" "$CLIENT_DIR/"
    cp "$SKELETON_DIR/outputs.tf" "$CLIENT_DIR/"
    
    # Copy modules directory
    cp -r "$SKELETON_DIR/modules" "$CLIENT_DIR/"
    
    # Copy scripts directory
    cp -r "$SKELETON_DIR/scripts" "$CLIENT_DIR/"
    
    log_success "Skeleton files copied"
}

create_client_configuration() {
    log_info "Creating client configuration..."
    
    # Create terraform.tfvars from template
    cp "$SKELETON_DIR/terraform.tfvars.example" "$CLIENT_DIR/terraform.tfvars"
    
    # Replace placeholders in terraform.tfvars
    sed -i.bak "s/your-client-name/$CLIENT_NAME/g" "$CLIENT_DIR/terraform.tfvars"
    sed -i.bak "s/your-project-name/$CLIENT_NAME/g" "$CLIENT_DIR/terraform.tfvars"
    sed -i.bak "s/your-client.com/$DOMAIN/g" "$CLIENT_DIR/terraform.tfvars"
    sed -i.bak "s/monthly_budget_limit = 100/monthly_budget_limit = $BUDGET/g" "$CLIENT_DIR/terraform.tfvars"
    
    # Remove backup file
    rm "$CLIENT_DIR/terraform.tfvars.bak"
    
    log_success "Client configuration created"
}

create_client_documentation() {
    log_info "Creating client documentation..."
    
    # Create client-specific README
    cat > "$CLIENT_DIR/README.md" << EOF
# $CLIENT_NAME Infrastructure

This directory contains the infrastructure configuration for $CLIENT_NAME.

## Configuration

- **Client**: $CLIENT_NAME
- **Environment**: $ENVIRONMENT
- **Domain**: $DOMAIN
- **Budget**: \$$BUDGET/month
- **Architecture**: Serverless

## Quick Start

### 1. Deploy Infrastructure

\`\`\`bash
cd $CLIENT_NAME
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
\`\`\`

### 2. Verify Deployment

\`\`\`bash
# Check CloudFront distribution
aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$CLIENT_NAME CloudFront Distribution']"

# Check API Gateway
aws apigateway get-rest-apis --query "items[?name=='$CLIENT_NAME-api']"

# Check DynamoDB tables
aws dynamodb list-tables --query "TableNames[?contains(@, '$CLIENT_NAME')]"
\`\`\`

## Cost Information

### Monthly Costs (Estimated)
- **Lambda Functions**: \$0.00-\$5.00 (pay-per-request)
- **API Gateway**: \$0.00-\$3.50 (pay-per-request)
- **DynamoDB**: \$0.00-\$2.00 (pay-per-request)
- **S3 Storage**: \$0.46 (20GB)
- **CloudFront**: \$0.00-\$8.50 (Global CDN)
- **Route53**: \$0.50 (DNS management)
- **Total**: \$0.96-\$20.91/month

## Support

- **Technical Support**: support@robert-consulting.net
- **Documentation**: https://docs.robert-consulting.net
- **GitHub Issues**: https://github.com/robert-consulting/skeleton-client/issues

---

**Client infrastructure created successfully!**
**Ready for deployment.**
EOF
    
    log_success "Client documentation created"
}

create_client_scripts() {
    log_info "Creating client-specific scripts..."
    
    # Make scripts executable
    chmod +x "$CLIENT_DIR/scripts"/*.sh
    
    # Create client-specific deployment script
    cat > "$CLIENT_DIR/deploy.sh" << EOF
#!/bin/bash

# $CLIENT_NAME Deployment Script
# This script deploys the infrastructure for $CLIENT_NAME

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLIENT_NAME="$CLIENT_NAME"
ENVIRONMENT="$ENVIRONMENT"
DOMAIN="$DOMAIN"
BUDGET="$BUDGET"

# Functions
log_info() {
    echo -e "\${BLUE}[INFO]\${NC} \$1"
}

log_success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$1"
}

log_warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

log_error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Main deployment function
main() {
    log_info "Starting deployment for $CLIENT_NAME"
    log_info "Environment: $ENVIRONMENT"
    log_info "Domain: $DOMAIN"
    log_info "Budget: \$$BUDGET/month"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -var-file=terraform.tfvars -out=tfplan
    
    # Ask for confirmation
    echo
    log_warning "About to deploy infrastructure for $CLIENT_NAME"
    log_warning "Expected monthly cost: \$0.96-\$20.91"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ \$REPLY =~ ^[Yy]\$ ]]; then
        # Apply deployment
        log_info "Deploying infrastructure..."
        terraform apply tfplan
        
        log_success "Infrastructure deployed successfully!"
        log_info "Check the outputs for connection information"
    else
        log_info "Deployment cancelled by user"
        exit 0
    fi
}

# Run main function
main "\$@"
EOF
    
    chmod +x "$CLIENT_DIR/deploy.sh"
    
    log_success "Client-specific scripts created"
}

generate_client_summary() {
    log_info "Generating client summary..."
    
    # Create client summary
    cat > "$CLIENT_DIR/CLIENT_SUMMARY.md" << EOF
# $CLIENT_NAME Client Summary

## Client Information
- **Client Name**: $CLIENT_NAME
- **Environment**: $ENVIRONMENT
- **Domain**: $DOMAIN
- **Budget**: \$$BUDGET/month
- **Architecture**: Serverless
- **Created**: $(date)

## Infrastructure Components

### Serverless Architecture
- **Lambda Functions**: API, Auth, Admin
- **API Gateway**: REST API endpoints
- **DynamoDB**: Users, Content, Analytics tables
- **S3 Storage**: Static, Uploads, Backups buckets
- **CloudFront**: Global CDN
- **Route53**: DNS management

### Cost Estimation
- **Monthly Cost**: \$0.96-\$20.91
- **Annual Cost**: \$11.52-\$250.92
- **Savings**: 94-99% vs traditional infrastructure

### Performance Characteristics
- **Concurrent Users**: 1000+ (auto-scaling)
- **Response Time**: 200ms (CloudFront + Lambda)
- **Availability**: 99.9% (AWS managed services)
- **Global Reach**: CloudFront edge locations

## Next Steps

1. **Review Configuration**: Check terraform.tfvars
2. **Deploy Infrastructure**: Run ./deploy.sh
3. **Verify Deployment**: Check AWS resources
4. **Monitor Costs**: Set up budget alerts
5. **Deploy Application**: Upload application code

## Support

- **Technical Support**: support@robert-consulting.net
- **Documentation**: https://docs.robert-consulting.net
- **GitHub Issues**: https://github.com/robert-consulting/skeleton-client/issues

---

**Client infrastructure template created successfully!**
**Ready for customization and deployment.**
EOF
    
    log_success "Client summary generated"
}

# Main function
main() {
    log_info "Creating client infrastructure for $CLIENT_NAME"
    log_info "Environment: $ENVIRONMENT"
    log_info "Domain: $DOMAIN"
    log_info "Budget: \$$BUDGET/month"
    
    # Run creation steps
    check_prerequisites
    create_client_directory
    copy_skeleton_files
    create_client_configuration
    create_client_documentation
    create_client_scripts
    generate_client_summary
    
    log_success "Client infrastructure created successfully!"
    log_info "Client directory: $CLIENTS_DIR/$CLIENT_NAME"
    log_info "Configuration file: $CLIENTS_DIR/$CLIENT_NAME/terraform.tfvars"
    log_info "Deployment script: $CLIENTS_DIR/$CLIENT_NAME/deploy.sh"
    log_info "Documentation: $CLIENTS_DIR/$CLIENT_NAME/README.md"
    log_info "Summary: $CLIENTS_DIR/$CLIENT_NAME/CLIENT_SUMMARY.md"
    
    echo
    log_info "Next steps:"
    log_info "1. Review the configuration: $CLIENTS_DIR/$CLIENT_NAME/terraform.tfvars"
    log_info "2. Deploy the infrastructure: cd $CLIENTS_DIR/$CLIENT_NAME && ./deploy.sh"
    log_info "3. Verify the deployment: Check AWS resources"
    log_info "4. Monitor costs: Set up budget alerts"
}

# Run main function
main "$@"
