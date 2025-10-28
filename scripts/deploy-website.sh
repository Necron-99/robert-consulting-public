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
  --exclude "**/node_modules/*" \
  --exclude "**/package.json" \
  --exclude "**/package-lock.json" \
  --exclude "**/yarn.lock" \
  --exclude "**/pnpm-lock.yaml" \
  --exclude "**/bun.lockb" \
  --exclude "**/tsconfig.json" \
  --exclude "**/webpack.config.js" \
  --exclude "**/babel.config.js" \
  --exclude "**/jest.config.js" \
  --exclude "**/rollup.config.js" \
  --exclude "**/vite.config.js" \
  --exclude "**/tailwind.config.js" \
  --exclude "**/postcss.config.js" \
  --exclude "**/next.config.js" \
  --exclude "**/nuxt.config.js" \
  --exclude "**/vue.config.js" \
  --exclude "**/angular.json" \
  --exclude "**/eslint.config.js" \
  --exclude "**/.eslintrc.json" \
  --exclude "**/.prettierrc.json" \
  --exclude "**/.gitignore" \
  --exclude "**/.gitattributes" \
  --exclude "**/.vscode/*" \
  --exclude "**/views/*" \
  --exclude "**/web/*" \
  --exclude "**/monitoring-script.js" \
  --exclude "**/test-dashboard-strict.js" \
  --exclude "**/test-dashboard-ui.js" \
  --exclude "**/dashboard.json" \
  --exclude "**/update-version.ps1" \
  --exclude "**/version-fallback.json" \
  --exclude "**/.deployignore" \
  --exclude "**/README.md" \
  --exclude "**/LICENSE" \
  --exclude "**/sitemap.xml" \
  --exclude "**/robots.txt" \
  --exclude "**/humans.txt" \
  --exclude "**/crossdomain.xml" \
  --exclude "**/favicon.ico" \
  --exclude "**/apple-touch-icon.png" \
  --exclude "**/manifest.json" \
  --exclude "**/browserconfig.xml" \
  --exclude "**/tile.png" \
  --exclude "**/tile-wide.png" \
  --exclude "**/safari-pinned-tab.svg" \
  --exclude "**/web.config" \
  --exclude "**/.htaccess" \
  --exclude "**/nginx.conf" \
  --exclude "**/Procfile" \
  --exclude "**/Dockerfile" \
  --exclude "**/docker-compose.yml" \
  --exclude "**/Jenkinsfile" \
  --exclude "**/Vagrantfile" \
  --exclude "**/Gemfile" \
  --exclude "**/Gemfile.lock" \
  --exclude "**/Rakefile" \
  --exclude "**/composer.json" \
  --exclude "**/composer.lock" \
  --exclude "**/phpcs.xml" \
  --exclude "**/phpunit.xml" \
  --exclude "**/phpstan.neon" \
  --exclude "**/psalm.xml"

# 2) Upload blog-posts without --delete to preserve existing posts in bucket
if [ -d "$SITE_DIR/blog-posts" ]; then
  aws s3 sync "$SITE_DIR/blog-posts" "s3://$BUCKET/blog-posts/" \
    --exclude "**/.DS_Store"
fi

echo "Deployment complete: main site synced with delete; blog-posts preserved."
