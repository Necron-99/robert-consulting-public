# Temporary local backend for importing resources
terraform {
  backend "local" {
    path = "terraform-local.tfstate"
  }
}
