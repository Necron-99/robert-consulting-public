# Simple Staging Access Control
# Uses a basic query parameter approach for staging access

# CloudFront Function for simple staging access control
resource "aws_cloudfront_function" "staging_access_control" {
  name    = "staging-access-control"
  runtime = "cloudfront-js-1.0"
  comment = "Simple staging access control with query parameter"
  publish = true
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var querystring = request.querystring;
    
    // Check if this is a staging request
    if (request.headers.host && request.headers.host.value.includes('staging.robertconsulting.net')) {
        // Check for access key
        if (querystring.key && querystring.key.value === 'staging-access-2025') {
            // Valid access key, allow request
            return request;
        } else {
            // No valid access key, return access denied page
            return {
                statusCode: 403,
                statusDescription: 'Forbidden',
                headers: {
                    'content-type': { value: 'text/html' }
                },
                body: {
                    encoding: 'text',
                    data: '<!DOCTYPE html><html><head><title>Staging Access Required</title><style>body{font-family:Arial,sans-serif;text-align:center;padding:50px;background:#f5f5f5;}h1{color:#333;}.container{max-width:600px;margin:0 auto;background:white;padding:30px;border-radius:8px;box-shadow:0 2px 10px rgba(0,0,0,0.1);}p{color:#666;line-height:1.6;}.code{background:#f8f9fa;padding:10px;border-radius:4px;font-family:monospace;margin:20px 0;}</style></head><body><div class="container"><h1>🔒 Staging Access Required</h1><p>This is a staging environment that requires an access key.</p><p>To access staging, add the following parameter to your URL:</p><div class="code">?key=staging-access-2025</div><p>Example: <code>https://staging.robertconsulting.net/dashboard.html?key=staging-access-2025</code></p><p><strong>Note:</strong> This is a simple access control method. For production use, consider more robust authentication.</p></div></body></html>'
                }
            };
        }
    }
    
    // Not a staging request, allow through
    return request;
}
EOT
}

# Output the staging access information
output "staging_access_info" {
  description = "Information about staging access"
  value = {
    access_key = "staging-access-2025"
    example_url = "https://staging.robertconsulting.net/dashboard.html?key=staging-access-2025"
    note = "Add ?key=staging-access-2025 to any staging URL to access it"
  }
}
