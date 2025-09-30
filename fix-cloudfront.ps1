# Fix CloudFront Configuration Script
Write-Host "🔧 Fixing CloudFront configuration..."

# Read the fresh configuration
$config = Get-Content "fresh-config.json" | ConvertFrom-Json

Write-Host "📊 Current settings:"
Write-Host "  Default TTL: $($config.DistributionConfig.DefaultCacheBehavior.DefaultTTL)"
Write-Host "  Max TTL: $($config.DistributionConfig.DefaultCacheBehavior.MaxTTL)"

# Apply optimizations
Write-Host "⚙️ Applying optimizations..."

# Update cache settings
$config.DistributionConfig.DefaultCacheBehavior.DefaultTTL = 86400  # 24 hours
$config.DistributionConfig.DefaultCacheBehavior.MaxTTL = 31536000    # 1 year

# Update comment
$config.DistributionConfig.Comment = "Optimized for cost and performance - $(Get-Date -Format 'yyyy-MM-dd')"

Write-Host "📝 New settings:"
Write-Host "  Default TTL: $($config.DistributionConfig.DefaultCacheBehavior.DefaultTTL) (24 hours)"
Write-Host "  Max TTL: $($config.DistributionConfig.DefaultCacheBehavior.MaxTTL) (1 year)"

# Save the optimized configuration
$config.DistributionConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "optimized-config-fixed.json" -Encoding UTF8

Write-Host "✅ Optimized configuration saved to optimized-config-fixed.json"
Write-Host ""
Write-Host "🚀 Now run this command:"
Write-Host "aws cloudfront update-distribution --id E36DBYPHUUKB3V --distribution-config file://optimized-config-fixed.json --if-match E1TSQUYZ6Z42DY"



<<<<<<< HEAD

=======
>>>>>>> a5db33b (Lots of changes.)
