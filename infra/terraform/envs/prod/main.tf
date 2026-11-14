locals {
  name_prefix = "resilient-commerce-prod"
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = local.name_prefix
  vpc_cidr    = "10.0.0.0/16"
}

module "ecr" {
  source = "../../modules/ecr"
}

module "eks" {
  source = "../../modules/eks"

  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnet_ids
  cluster_name = var.cluster_name

  depends_on = [module.vpc]
}