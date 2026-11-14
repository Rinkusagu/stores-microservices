locals {
  repositories = ["storefront", "catalog", "orders", "worker"]
  tags = merge(var.tags, {
    Project = "resilient-commerce"
  })
}

resource "aws_ecr_repository" "this" {
  for_each = toset(local.repositories)

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.tags, {
    Name = each.key
  })
}