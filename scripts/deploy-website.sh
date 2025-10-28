#!/usr/bin/env bash
set -euo pipefail

BUCKET="robert-consulting-website"
SITE_DIR="/Volumes/gitlab/robert-consulting-public/website"

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI not found" >&2
  exit 1
fi

# 1) Whitelist sync: only publish site assets; always preserve blog-posts here
aws s3 sync "$SITE_DIR" "s3://$BUCKET/" \
  --delete \
  --exclude "*" \
  --include "**/*.html" \
  --include "**/*.css" \
  --include "**/*.js" \
  --include "**/*.png" \
  --include "**/*.jpg" \
  --include "**/*.jpeg" \
  --include "**/*.gif" \
  --include "**/*.webp" \
  --include "**/*.svg" \
  --include "**/*.ico" \
  --include "**/*.woff" \
  --include "**/*.woff2" \
  --include "**/*.ttf" \
  --include "**/*.otf" \
  --include "**/*.eot" \
  --include "**/sitemap.xml" \
  --include "**/robots.txt" \
  --include "**/manifest.json" \
  --exclude "blog-posts/*"

# 2) Upload blog-posts without --delete to preserve existing posts in bucket
if [ -d "$SITE_DIR/blog-posts" ]; then
  aws s3 sync "$SITE_DIR/blog-posts" "s3://$BUCKET/blog-posts/" \
    --exclude "**/.DS_Store"
fi

echo "Deployment complete: main site synced with delete; blog-posts preserved."
