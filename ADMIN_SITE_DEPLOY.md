## Admin Site - Deploy & Access

### What this deploys
- S3 bucket (private) for static admin files
- CloudFront distribution with a CloudFront Function that enforces Basic Auth
- Optional Route53 A/ALIAS if you provide a domain and zone id

### Prerequisites
- Set two variables for Basic Auth:
  - `admin_basic_auth_username`
  - `admin_basic_auth_password`
- Optionally set:
  - `admin_domain_name` (e.g., admin.example.com)
  - `existing_route53_zone_id` (Route53 hosted zone id)

### Deploy
```bash
cd terraform
terraform init
terraform plan \
  -var="admin_basic_auth_username=<user>" \
  -var="admin_basic_auth_password=<pass>" \
  -var="admin_domain_name=<optional-admin.example.com>" \
  -var="existing_route53_zone_id=<optional-Zxxxxxxxxxxxx>"
terraform apply \
  -var="admin_basic_auth_username=<user>" \
  -var="admin_basic_auth_password=<pass>" \
  -var="admin_domain_name=<optional-admin.example.com>" \
  -var="existing_route53_zone_id=<optional-Zxxxxxxxxxxxx>"
```

### Upload the UI
```bash
# Copy UI files to the bucket
aws s3 sync ./admin s3://$(terraform output -raw admin_bucket) --delete
```

### Access
- If you set a domain: `https://<admin_domain_name>`
- Otherwise: output `admin_distribution_domain` or `admin_url`
- Browser will prompt for Basic Auth; use the username/password you passed in.

### Costs
- Designed for minimal cost: S3 + CloudFront (PriceClass_100) + Function. No Cognito.

### Rotate credentials
- Re-run `terraform apply` with a new `admin_basic_auth_password`.
- CloudFront function will be republished; changes take a few minutes to propagate.


