provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "resilient-commerce"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}