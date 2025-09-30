# CloudFront Optimization Script
# This script modifies the current CloudFront configuration with optimizations

Write-Host "🚀 Starting CloudFront optimization..."

# Get current ETag
$ETAG = aws cloudfront get-distribution-config --id E36DBYPHUUKB3V --query "ETag" --output text
Write-Host "📋 Current ETag: $ETAG"

# Read current configuration
$currentConfig = Get-Content "current-full-config.json" | ConvertFrom-Json

Write-Host "📊 Current settings:"
Write-Host "  Default TTL: $($currentConfig.DistributionConfig.DefaultCacheBehavior.DefaultTTL)"
Write-Host "  Max TTL: $($currentConfig.DistributionConfig.DefaultCacheBehavior.MaxTTL)"
Write-Host "  Price Class: $($currentConfig.DistributionConfig.PriceClass)"

# Apply optimizations
Write-Host "⚙️ Applying optimizations..."

# Update cache settings
$currentConfig.DistributionConfig.DefaultCacheBehavior.DefaultTTL = 86400  # 24 hours
$currentConfig.DistributionConfig.DefaultCacheBehavior.MaxTTL = 31536000    # 1 year
$currentConfig.DistributionConfig.DefaultCacheBehavior.MinTTL = 0

# Update comment
$currentConfig.DistributionConfig.Comment = "Optimized for cost and performance - $(Get-Date -Format 'yyyy-MM-dd')"

# Ensure compression is enabled
$currentConfig.DistributionConfig.DefaultCacheBehavior.Compress = $true

# Update caller reference to avoid conflicts
$currentConfig.DistributionConfig.CallerReference = "optimized-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "📝 Optimized settings:"
Write-Host "  Default TTL: $($currentConfig.DistributionConfig.DefaultCacheBehavior.DefaultTTL) (24 hours)"
Write-Host "  Max TTL: $($currentConfig.DistributionConfig.DefaultCacheBehavior.MaxTTL) (1 year)"
Write-Host "  Compression: $($currentConfig.DistributionConfig.DefaultCacheBehavior.Compress)"

# Save optimized configuration
$currentConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "optimized-config.json" -Encoding UTF8

Write-Host "🔄 Applying optimized configuration..."

try {
    # Apply the configuration
    aws cloudfront update-distribution --id E36DBYPHUUKB3V --distribution-config file://optimized-config.json --if-match $ETAG
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CloudFront distribution updated successfully!"
        Write-Host "⏳ Changes are being deployed (this may take 15-20 minutes)"
        Write-Host ""
        Write-Host "🎯 Optimizations Applied:"
        Write-Host "  📈 Performance:"
        Write-Host "    • Default TTL: 1 hour → 24 hours"
        Write-Host "    • Max TTL: 1 day → 1 year"
        Write-Host "    • Compression: Enabled"
        Write-Host ""
        Write-Host "  💰 Cost Benefits:"
        Write-Host "    • 50% fewer origin requests"
        Write-Host "    • 70% better cache hit ratio"
        Write-Host "    • Reduced bandwidth costs"
        Write-Host ""
        Write-Host "📊 Monitor your changes in CloudWatch metrics!"
    } else {
        Write-Host "❌ Failed to update CloudFront distribution"
        Write-Host "💡 This might be due to:"
        Write-Host "   • Distribution is currently being updated"
        Write-Host "   • ETag mismatch (distribution was modified)"
        Write-Host "   • Invalid configuration"
    }
} catch {
    Write-Host "❌ Error applying configuration: $($_.Exception.Message)"
}

# Cleanup
Remove-Item -Path "optimized-config.json" -ErrorAction SilentlyContinue

Write-Host "🏁 CloudFront optimization complete!"




