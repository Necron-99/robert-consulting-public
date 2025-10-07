## Clients Management Hub

### Purpose
Centralized, copy/paste-friendly runbooks to manage client AWS accounts and Terraform stacks from the management account.

### Prerequisites
- Management AWS account credentials configured in your shell or CI
- Per-client roles present in client accounts:
  - `RobertClientDeploymentRole` (Terraform applies)
  - `RobertConsoleAccessRole` (optional console access)
- Terraform remote state S3 and DynamoDB locking configured (see `TERRAFORM_STATE_MANAGEMENT.md`)

### Directory layout
- Client stacks: `terraform/clients/<client>/`
- Shared module: `terraform/modules/client-infrastructure/`

---

### Onboard a new client
1) If the account is in your AWS Organization
```bash
cd terraform/clients/skeleton
terraform init && terraform plan && terraform apply
# This bootstraps roles in the client account using OrganizationAccountAccessRole
```

2) If the account is external (not in your Org)
- Ask the client to deploy an IAM role trusted by your management account with ExternalId (see `terraform/org/client-role.tf` for trust policy example)

3) Create the client stack directory
```bash
cp -r terraform/clients/skeleton terraform/clients/<client>
cd terraform/clients/<client>
```

4) Configure the module in `main.tf`
- Set:
  - `client_name`, `client_domain`, `additional_domains`
  - `existing_cloudfront_distribution_id` if reusing an existing distribution
  - `existing_route53_zone_id` if reusing an existing hosted zone
  - `existing_acm_certificate_arn` if using an issued certificate in us-east-1

5) Initialize and deploy
```bash
terraform init
terraform plan
terraform apply
```

---

### Adopting existing resources (no recreation)

Set module inputs in the client stack `main.tf`:
```hcl
existing_cloudfront_distribution_id = "E..."
existing_route53_zone_id            = "Z..."
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:..."
```

Import existing Route53 records to avoid "already exists" errors:
```bash
# Apex A/ALIAS
terraform import 'module.infra.aws_route53_record.website[0]' ZONEID_example.com_A

# Additional domains (indexes align to additional_domains order)
terraform import 'module.infra.aws_route53_record.additional[0]' ZONEID_www.example.com_A
terraform import 'module.infra.aws_route53_record.additional[1]' ZONEID_app.example.com_A
```

Notes:
- Import ID format: `<ZONEID>_<record-name>_<TYPE>`; record-name FQDN without trailing dot.
- If your existing records are CNAMEs, either convert them in Route53 to A/ALIAS and import as above, or temporarily change resource `type = "CNAME"`, import with `_CNAME`, and then migrate.

---

### Assume role (manual testing or scripting)
```bash
# Deployment role
aws sts assume-role \
  --role-arn arn:aws:iam::<CLIENT_ACCOUNT_ID>:role/RobertClientDeploymentRole \
  --role-session-name rc-deploy-<client>

# Optional console role
aws sts assume-role \
  --role-arn arn:aws:iam::<CLIENT_ACCOUNT_ID>:role/RobertConsoleAccessRole \
  --role-session-name rc-console-<client>
```

Export credentials from the assume-role response before running Terraform, or rely on the provider `assume_role` block in the client `main.tf`.

---

### Standard Terraform workflow
```bash
cd terraform/clients/<client>
terraform init -upgrade
terraform plan
terraform apply
```

Drift checks (optional):
```bash
./terraform/drift-detection.sh check
```

---

### DNS and certificates
- Use `existing_route53_zone_id` to manage records in an existing hosted zone.
- Use `existing_acm_certificate_arn` (us-east-1) to enable CloudFront aliases.
- The module will manage A/ALIAS records for apex and each domain in `additional_domains`.

---

### WAF attachment
- If you maintain a WAF for the distribution, attach it at the distribution level.
- Extension option (future): add a module input `existing_waf_web_acl_arn` and associate to CloudFront in the stack.

---

### Cleanup checklist (safe removal)
- Old CloudFront distributions no longer referenced by Terraform
- Old Route53 hosted zones and records not in use
- Unused ACM certificates (superseded or pending)
- S3 website buckets not used as active origins
- CloudWatch dashboards/alarms targeting old distribution IDs

Always review `terraform plan` to confirm only intended resources are destroyed.

---

### Quick runbooks

1) Import existing DNS records
```bash
terraform import 'module.infra.aws_route53_record.website[0]' ZONEID_example.com_A
terraform import 'module.infra.aws_route53_record.additional[0]' ZONEID_www.example.com_A
terraform import 'module.infra.aws_route53_record.additional[1]' ZONEID_app.example.com_A
```

2) Point DNS to an existing CloudFront distribution
```hcl
# in module block
existing_cloudfront_distribution_id = "E..."
existing_route53_zone_id            = "Z..."
existing_acm_certificate_arn       = "arn:aws:acm:us-east-1:..."
```

3) Bootstrap roles in a client account (Org-managed)
```bash
cd terraform/clients/skeleton
terraform init && terraform apply
```

---

### Optional: Private Admin Site (proposal)
- Stack: Static Next.js/React app + API (AWS Lambda) + Cognito/Auth
- Features:
  - Client registry (name, account ID, envs, module settings)
  - One-click: plan/apply, drift check, DNS import helpers
  - Status dashboards (CF, S3, WAF, budgets)
  - Audit trail (who changed what, when)
- Hosting: S3 + CloudFront; auth via Cognito; API uses the management account to assume `RobertClientDeploymentRole` per client.

If you want this implemented, create a new directory `admin/` and we can scaffold it with IaC and CI.


