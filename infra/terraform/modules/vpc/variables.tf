variable "name_prefix" {
  type        = string
  description = "Prefix for VPC and related resource names."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags merged onto all resources."
}