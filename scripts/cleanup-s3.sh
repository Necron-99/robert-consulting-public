#!/bin/bash

# Clean up S3 bucket - remove unnecessary files
echo "=== CLEANING UP S3 BUCKET ==="

# Files to remove from S3
FILES_TO_REMOVE=(
    "nav-isolated-test.html"
    "nav-test.html"
    "easter-egg-test.html"
    "staging-access.html"
    "gone-fishing.html"
    "error.html"
    "learning-consolidated-preview.html"
    "plex-recommendations-section.html"
    "plex-recommendations-styles.css"
    "test-comprehensive-secrets.md"
    "test-fixed-validation.md"
    "test-improved-secrets.md"
    "test-ip-bypass.md"
    "test-node-modules-fix.md"
    "test-security-fixes.md"
    "test-targeted-secrets.md"
    "test-validation.md"
    "test-workflow.md"
    "version-fallback.json"
    "deploy-website.sh"
    "deploy-with-invalidation.sh"
    "secure-api-deployment.sh"
    "configure-api.sh"
)

# Remove files from S3
for file in "${FILES_TO_REMOVE[@]}"; do
    echo "Removing $file from S3..."
    aws s3 rm "s3://robert-consulting-website/$file" || echo "File $file not found in S3"
done

echo "=== S3 CLEANUP COMPLETE ==="
