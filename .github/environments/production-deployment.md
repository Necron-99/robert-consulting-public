# Production Deployment Environment

This environment controls access to production deployments and requires manual approval.

## Configuration

- **Protection Rules**: Manual approval required
- **Reviewers**: Repository administrators
- **Deployment Branch**: `main` only
- **Environment URL**: https://robertconsulting.net

## Approval Process

1. **Automatic Staging Deployment**: All commits to `main` are automatically deployed to staging
2. **Comprehensive Testing**: Automated test battery runs against staging
3. **Manual Review**: Human approval required before production deployment
4. **Production Deployment**: Approved changes are deployed to production
5. **Post-deployment Monitoring**: Health checks and validation

## Emergency Procedures

- **Skip Tests**: Use `skip_tests: true` for emergency deployments (not recommended)
- **Force Production**: Use `force_production: true` to bypass staging (emergency only)

## Security

- All deployments are logged and auditable
- Staging environment is IP-restricted for security testing
- Production deployments require explicit approval
- Rollback procedures are available if needed
