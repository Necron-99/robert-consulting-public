#!/bin/bash

# Package CloudWatch Synthetics Canaries
# This script creates the zip files needed for CloudWatch Synthetics

set -e

echo "📦 Packaging CloudWatch Synthetics Canaries..."

# Create synthetics directory if it doesn't exist
mkdir -p synthetics

# Package performance monitor
echo "📦 Packaging performance monitor canary..."
cd synthetics
zip -r ../synthetics-performance-monitor.zip performance-monitor.js
cd ..

# Package security headers monitor (reuse performance monitor script)
echo "📦 Packaging security headers monitor canary..."
cp synthetics/performance-monitor.js synthetics/security-headers-monitor.js
cd synthetics
zip -r ../synthetics-security-headers.zip security-headers-monitor.js
cd ..

# Clean up temporary files
rm -f synthetics/security-headers-monitor.js

echo "✅ Synthetics canaries packaged successfully!"
echo "📁 Files created:"
echo "   - synthetics-performance-monitor.zip"
echo "   - synthetics-security-headers.zip"
echo ""
echo "🚀 Ready to deploy with: terraform apply"
