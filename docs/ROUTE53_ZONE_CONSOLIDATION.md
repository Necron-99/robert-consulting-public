# Route53 Zone Consolidation Guide

## Problem

You have **3 duplicate hosted zones** for `robertconsulting.net`:
- `Z05682173V2H2T5QWU8P0` - 7 records
- `Z0219036XF42XEMQOJ4` - 10 records  
- `Z0232243368137F38UDI1` - 20 records

Additionally, Terraform is trying to **create a 4th zone** (`aws_route53_zone.main`).

## Why This Is a Problem

- **DNS Conflicts**: Multiple zones can cause inconsistent DNS resolution
- **Cost**: Each zone costs $0.50/month (though first zone is free)
- **Confusion**: Hard to know which zone is actually being used
- **Terraform Issues**: Terraform will try to create new zones instead of using existing ones

## Solution: Consolidate to ONE Zone

### Step 1: Identify the Active Zone

Check your domain registrar (Namecheap, etc.) to see which nameservers are configured. The zone with matching nameservers is the **active** one.

```bash
# Run the analysis script
./scripts/consolidate-route53-zones.sh
```

This will show you:
- Which zone Terraform is using (if any)
- Record counts for each zone
- Key records in each zone
- Recommendations

### Step 2: Determine Which Zone to Keep

**Recommended approach:**
1. **Check domain registrar** - Which nameservers are configured?
2. **Check Terraform state** - Is one already imported?
3. **Check record count** - Zone with most records is likely the active one
4. **Check record content** - Which zone has the correct CloudFront aliases?

### Step 3: Import the Correct Zone into Terraform

Once you've identified which zone to keep (let's say `Z05682173V2H2T5QWU8P0`):

```bash
cd terraform

# Import the existing zone (replace with your chosen zone ID)
terraform import aws_route53_zone.main Z05682173V2H2T5QWU8P0
```

### Step 4: Export Records from Other Zones (Backup)

Before deleting, export records from the zones you'll remove:

```bash
# Export records from zones you'll delete
aws route53 list-resource-record-sets --hosted-zone-id Z0219036XF42XEMQOJ4 > zone-2-backup.json
aws route53 list-resource-record-sets --hosted-zone-id Z0232243368137F38UDI1 > zone-3-backup.json
```

### Step 5: Verify All Records Are in the Kept Zone

Make sure all important records (A, AAAA, CNAME, MX, TXT) are in the zone you're keeping. If any are missing, you'll need to recreate them.

### Step 6: Delete Duplicate Zones

**⚠️ WARNING: This is permanent and cannot be undone!**

Only delete zones after:
- ✅ You've verified which zone is active
- ✅ You've backed up all records
- ✅ You've confirmed all records are in the zone you're keeping
- ✅ You've imported the correct zone into Terraform

```bash
# Delete duplicate zones (ONLY after verification!)
aws route53 delete-hosted-zone --id Z0219036XF42XEMQOJ4
aws route53 delete-hosted-zone --id Z0232243368137F38UDI1
```

### Step 7: Update Terraform Configuration

After importing, verify Terraform uses the correct zone:

```bash
cd terraform
terraform plan
```

The plan should show:
- ✅ `aws_route53_zone.main` - no changes (already imported)
- ✅ Route53 records using the correct zone_id

## Quick Reference

**Zone IDs:**
- `Z05682173V2H2T5QWU8P0` - 7 records (referenced in import scripts)
- `Z0219036XF42XEMQOJ4` - 10 records
- `Z0232243368137F38UDI1` - 20 records (referenced in dashboard-api.tf)

**Terraform Resource:**
- `aws_route53_zone.main` in `terraform/domain-namecheap.tf`

## Tools

- `./scripts/consolidate-route53-zones.sh` - Analyze zones and recommend which to keep
- `./scripts/generate-route53-imports.sh` - Generate import commands for Route53 records

