# CloudFront Distribution Analysis & Recommendations

## Current Distributions (5 total)

### ✅ **Production Website** - E36DBYPHUUKB3V
- **Purpose**: Main production site (`robertconsulting.net`, `www.robertconsulting.net`)
- **Status**: ✅ **KEEP** - Required for production
- **Reason**: Custom domain, SSL, security headers, CDN benefits

### ❓ **Staging Website** - E23HB5TWK5BF44
- **Purpose**: Staging/testing environment (`staging.robertconsulting.net`)
- **Current Setup**: CloudFront + WAF + IP restrictions + SSL
- **Question**: Do we need CloudFront for staging?

**Analysis:**
- Staging has WAF for IP restrictions (only allows specific IPs)
- CloudFront function for access control
- SSL certificate for HTTPS
- Security headers

**Recommendation:**
- **Option A (Keep CloudFront)**: If you need IP restrictions, SSL, and security headers
- **Option B (Remove CloudFront)**: If you just need simple S3 testing, you can:
  - Point `staging.robertconsulting.net` directly to S3 website endpoint
  - Remove CloudFront distribution
  - **Cost Savings**: ~$0.01-0.10/month (minimal, but simpler)
  - **Trade-off**: No IP restrictions, no SSL (HTTP only), no security headers

### ❓ **Admin Site** - E9UWTOXNT30YT
- **Purpose**: "Clients Admin Hub" - dashboard for managing client deployments
- **Current Setup**: CloudFront + Basic Auth + No custom domain
- **Question**: What is this used for?

**Analysis:**
- Admin interface for managing:
  - Client sites (Bailey Lessons, etc.)
  - Client deployments
  - Infrastructure status
  - Runbooks
- Protected with Basic Auth via CloudFront function
- No custom domain (uses CloudFront default domain)
- Currently at: `d2vytd4g8dnppc.cloudfront.net`

**Recommendation:**
- **If actively used**: Keep it, but consider adding a custom domain (`admin.robertconsulting.net`)
- **If not used**: Can be removed to simplify infrastructure
- **Alternative**: Could use S3 website hosting with basic auth, but CloudFront provides better security

### ✅ **Plex Recommendations (Active)** - E3T1Z34I8CU20F
- **Purpose**: Plex recommendations project (`plex.robertconsulting.net`)
- **Status**: ✅ **KEEP** - Active with custom domain

### ❌ **Plex Recommendations (Duplicate)** - E36R64EU3W6DCP
- **Purpose**: Duplicate/unused Plex distribution
- **Status**: ❌ **DELETE** - No alias, no requests, duplicate

## Recommendations Summary

### Immediate Actions:
1. ✅ **Delete duplicate Plex distribution** (E36R64EU3W6DCP)
2. ❓ **Decide on staging**: Keep CloudFront or switch to direct S3?
3. ❓ **Decide on admin site**: Keep, remove, or add custom domain?

### Cost Impact:
- **Staging CloudFront**: ~$0.01-0.10/month (minimal)
- **Admin CloudFront**: ~$0.01-0.10/month (minimal)
- **Total potential savings**: ~$0.02-0.20/month (very small)

### Complexity Impact:
- **Removing staging CloudFront**: Simplifies infrastructure, but loses IP restrictions and SSL
- **Removing admin CloudFront**: Simplifies infrastructure, but loses basic auth and security headers

## Questions to Answer:

1. **Staging**: Do you need IP restrictions and HTTPS for staging, or is simple S3 HTTP access sufficient?
2. **Admin Site**: 
   - Is the admin site actively being used?
   - Do you need it at all?
   - Should it have a custom domain (`admin.robertconsulting.net`)?

## Next Steps:

1. Review this analysis
2. Decide on staging and admin site usage
3. Execute cleanup (remove duplicate Plex distribution)
4. Optionally simplify staging/admin if not needed

