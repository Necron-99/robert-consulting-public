#!/usr/bin/env bash
set -euo pipefail

BUCKET="robert-consulting-website"
SITE_DIR="/Volumes/gitlab/robert-consulting-public/website"

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI not found" >&2
  exit 1
fi

# 1) Sync everything except blog-posts with --delete to keep site tidy
aws s3 sync "$SITE_DIR" "s3://$BUCKET/" \
  --delete \
  --exclude "blog-posts/*" \
  --exclude "**/.DS_Store" \
  --exclude "**/node_modules/*"

# 2) Upload blog-posts without --delete to preserve existing posts in bucket
if [ -d "$SITE_DIR/blog-posts" ]; then
  aws s3 sync "$SITE_DIR/blog-posts" "s3://$BUCKET/blog-posts/" \
    --exclude "**/.DS_Store"
fi

echo "Deployment complete: main site synced with delete; blog-posts preserved."
