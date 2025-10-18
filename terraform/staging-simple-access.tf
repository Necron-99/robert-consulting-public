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
    var uri = request.uri;
    
    // Check if this is a staging request
    if (request.headers.host && request.headers.host.value.includes('staging.robertconsulting.net')) {
        // Allow static assets without secret
        if (uri.includes('/css/') || uri.includes('/js/') || 
            uri.endsWith('.css') || uri.endsWith('.js') || 
            uri.endsWith('.ico') || uri.endsWith('.png') || 
            uri.endsWith('.jpg') || uri.endsWith('.jpeg') || 
            uri.endsWith('.gif') || uri.endsWith('.svg') || 
            uri.endsWith('.woff') || uri.endsWith('.woff2') || 
            uri.endsWith('.ttf') || uri.endsWith('.eot')) {
            return request;
        }
        
        // Check for secret parameter
        if (querystring.secret && querystring.secret.value === 'staging-access-2025') {
            return request;
        }
        
        // Return access denied
        return {
            statusCode: 403,
            statusDescription: 'Forbidden',
            headers: {
                'content-type': { value: 'text/html' }
            },
            body: {
                encoding: 'text',
                data: '<!DOCTYPE html><html><head><title>Staging Access Required</title></head><body><h1>Staging Access Required</h1><p>Add ?secret=staging-access-2025 to your URL</p></body></html>'
            }
        };
    }
    
    return request;
}
EOT
}

# Output the staging access information
output "staging_access_info" {
  description = "Information about staging access"
  value = {
    access_secret = "staging-access-2025"
    example_url   = "https://staging.robertconsulting.net/dashboard.html?secret=staging-access-2025"
    header_name   = "x-staging-secret"
    header_value  = "staging-access-2025"
    note          = "Add ?secret=staging-access-2025 to any staging URL to access it"
  }
}
