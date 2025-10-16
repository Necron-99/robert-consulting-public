#!/bin/bash

# AWS Account ID Cleanup Script
# This script removes hardcoded AWS Account IDs from all files in the repository

set -e

echo "🔍 AWS Account ID Cleanup Script"
echo "================================"

# Define the account IDs to remove
ACCOUNT_ID_1="228480945348"
ACCOUNT_ID_2="737915157697"

# Backup directory
BACKUP_DIR="backup/aws-account-cleanup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📁 Creating backup in: $BACKUP_DIR"

# Function to clean a file
clean_file() {
    local file="$1"
    local account_id="$2"
    
    if [ -f "$file" ]; then
        echo "🧹 Cleaning $file (removing $account_id)"
        
        # Create backup
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
        
        # Replace account ID with variable reference
        sed -i.tmp "s/$account_id/\${data.aws_caller_identity.current.account_id}/g" "$file"
        rm -f "$file.tmp"
        
        # Count replacements made
        local count=$(grep -c "$account_id" "$file" 2>/dev/null || echo "0")
        if [ "$count" -eq 0 ]; then
            echo "   ✅ Successfully cleaned $file"
        else
            echo "   ⚠️  Warning: $count instances still found in $file"
        fi
    fi
}

# Function to clean documentation files (replace with placeholder)
clean_doc_file() {
    local file="$1"
    local account_id="$2"
    
    if [ -f "$file" ]; then
        echo "📝 Cleaning documentation $file (replacing $account_id with [REDACTED])"
        
        # Create backup
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
        
        # Replace with [REDACTED] placeholder
        sed -i.tmp "s/$account_id/[REDACTED]/g" "$file"
        rm -f "$file.tmp"
        
        echo "   ✅ Successfully cleaned documentation $file"
    fi
}

echo ""
echo "🗑️  PHASE 1: Removing Terraform State Files (CRITICAL)"
echo "======================================================"

# Remove terraform state files (these should never be in public repos)
if [ -f "terraform/terraform.tfstate.backup" ]; then
    echo "🚨 CRITICAL: Removing terraform.tfstate.backup (contains 133 account IDs)"
    mv "terraform/terraform.tfstate.backup" "$BACKUP_DIR/"
    echo "   ✅ Moved to backup directory"
fi

if [ -f "terraform.tfstate" ]; then
    echo "🚨 CRITICAL: Removing terraform.tfstate"
    mv "terraform.tfstate" "$BACKUP_DIR/"
    echo "   ✅ Moved to backup directory"
fi

echo ""
echo "🔧 PHASE 2: Cleaning Terraform Configuration Files"
echo "================================================="

# Clean Terraform files (replace with variable references)
TERRAFORM_FILES=(
    "terraform/org/management-role.tf"
    "terraform/org/client-role.tf"
    "terraform/modules/client-infrastructure/remote-management.tf"
    "terraform/clients/baileylessons/role.tf"
    "terraform/clients/baileylessons/console-role.tf"
    "terraform/clients/baileylessons/main.tf"
)

for file in "${TERRAFORM_FILES[@]}"; do
    if [ -f "$file" ]; then
        clean_file "$file" "$ACCOUNT_ID_1"
        clean_file "$file" "$ACCOUNT_ID_2"
    fi
done

echo ""
echo "📝 PHASE 3: Cleaning Documentation Files"
echo "======================================="

# Clean documentation files (replace with [REDACTED])
DOC_FILES=(
    "docs/infrastructure/AWS_ACCOUNT_ID_REMOVAL_SUMMARY.md"
    "docs/guides/ADMIN_SITE_RESTORED.md"
    "docs/guides/ROLE_ASSUMPTION_UPDATE.md"
    "docs/guides/ADMIN_PAGE_BAILEYLESSONS_UPDATE.md"
    "docs/guides/BAILEYLESSONS_CONTENT_UPDATE.md"
    "docs/guides/BAILEYLESSONS_CLEANUP_PLAN.md"
    "docs/guides/BAILEYLESSONS_ADMIN_SETUP.md"
    "terraform/REMOTE_MANAGEMENT_GUIDE.md"
    "PUBLIC_REPOSITORY_ANALYSIS_REPORT.md"
)

for file in "${DOC_FILES[@]}"; do
    if [ -f "$file" ]; then
        clean_doc_file "$file" "$ACCOUNT_ID_1"
        clean_doc_file "$file" "$ACCOUNT_ID_2"
    fi
done

echo ""
echo "🔧 PHASE 4: Cleaning Script Files"
echo "================================"

# Clean script files
SCRIPT_FILES=(
    "scripts/switch-admin-auth.sh"
    "scripts/setup-waf-auth.sh"
    "scripts/deploy-admin-site.sh"
    "scripts/update-baileylessons-content.sh"
    "scripts/update-baileylessons-content-ssh.sh"
    "scripts/test-baileylessons-access.sh"
    "scripts/deploy-to-baileylessons.sh"
    "scripts/security/remote-management.sh"
)

for file in "${SCRIPT_FILES[@]}"; do
    if [ -f "$file" ]; then
        clean_file "$file" "$ACCOUNT_ID_1"
        clean_file "$file" "$ACCOUNT_ID_2"
    fi
done

echo ""
echo "🌐 PHASE 5: Cleaning HTML Files"
echo "=============================="

# Clean HTML files
HTML_FILES=(
    "admin/client-deployment.html"
)

for file in "${HTML_FILES[@]}"; do
    if [ -f "$file" ]; then
        clean_doc_file "$file" "$ACCOUNT_ID_1"
        clean_doc_file "$file" "$ACCOUNT_ID_2"
    fi
done

echo ""
echo "⚙️  PHASE 6: Cleaning Configuration Files"
echo "======================================="

# Clean configuration files
CONFIG_FILES=(
    "terraform/admin-domain.tfvars"
    "config/waf-rules-original.json"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        clean_doc_file "$file" "$ACCOUNT_ID_1"
        clean_doc_file "$file" "$ACCOUNT_ID_2"
    fi
done

echo ""
echo "🔍 PHASE 7: Verification"
echo "======================="

# Check for remaining instances
echo "Checking for remaining instances of $ACCOUNT_ID_1:"
REMAINING_1=$(grep -r "$ACCOUNT_ID_1" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=backup --exclude="*.zip" 2>/dev/null | wc -l || echo "0")

echo "Checking for remaining instances of $ACCOUNT_ID_2:"
REMAINING_2=$(grep -r "$ACCOUNT_ID_2" . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=backup --exclude="*.zip" 2>/dev/null | wc -l || echo "0")

echo ""
echo "📊 CLEANUP SUMMARY"
echo "=================="
echo "Account ID $ACCOUNT_ID_1: $REMAINING_1 instances remaining"
echo "Account ID $ACCOUNT_ID_2: $REMAINING_2 instances remaining"
echo "Backup created in: $BACKUP_DIR"

if [ "$REMAINING_1" -eq 0 ] && [ "$REMAINING_2" -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS: All AWS Account IDs have been removed!"
    echo "✅ Repository is now ready for public release"
else
    echo ""
    echo "⚠️  WARNING: Some instances may still remain"
    echo "🔍 Run the following to find remaining instances:"
    echo "   grep -r '$ACCOUNT_ID_1' . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=backup"
    echo "   grep -r '$ACCOUNT_ID_2' . --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=backup"
fi

echo ""
echo "📋 NEXT STEPS:"
echo "1. Review the changes made"
echo "2. Test Terraform configuration: terraform plan"
echo "3. Commit changes: git add . && git commit -m 'Remove AWS Account IDs for public release'"
echo "4. Repository is ready for public release!"

echo ""
echo "🔒 SECURITY NOTE:"
echo "Terraform state files have been moved to backup directory."
echo "These files should NEVER be committed to a public repository."
echo "Add '*.tfstate*' to .gitignore if not already present."
