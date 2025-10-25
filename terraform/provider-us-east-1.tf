# US East 1 Provider Configuration
# This provider is needed for ACM certificates and other resources

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
