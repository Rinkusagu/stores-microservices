variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources."
}

variable "cluster_name" {
  type        = string
  default     = "resilient-commerce-prod"
  description = "EKS cluster name."
}