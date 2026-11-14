variable "vpc_id" {
  type        = string
  description = "VPC where the cluster and nodes are deployed."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the EKS cluster and managed node group (typically private subnets)."
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster."
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "EC2 instance types for the managed node group."
}

variable "node_desired_size" {
  type        = number
  default     = 2
  description = "Desired number of worker nodes."
}

variable "node_min_size" {
  type        = number
  default     = 1
  description = "Minimum number of worker nodes."
}

variable "node_max_size" {
  type        = number
  default     = 4
  description = "Maximum number of worker nodes."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags merged onto all resources."
}