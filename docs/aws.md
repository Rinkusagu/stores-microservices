# Optional AWS infrastructure (Terraform)

This portfolio project ships **Azure-first** application and Kubernetes manifests. The layout under `infra/terraform` is an **optional** path for running the same workloads on AWS when you want a second cloud story for demos or interviews.

**Azure deployment and architecture for this repo are documented elsewhere and are out of scope for this file.**

## Layout

| Path | Purpose |
|------|---------|
| `infra/terraform/modules/vpc` | VPC, two AZs, public and private subnets, single NAT gateway, internet gateway, routing |
| `infra/terraform/modules/eks` | EKS cluster, one managed node group, IRSA for Cluster Autoscaler |
| `infra/terraform/modules/ecr` | Container registries: `storefront`, `catalog`, `orders`, `worker` |
| `infra/terraform/envs/prod` | Wires the three modules for a production-style stack |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- AWS credentials with permissions to create VPC, EKS, IAM, and ECR resources
- `kubectl` and `aws` CLI (for post-apply cluster access, not required for `terraform validate`)

## Apply order

Terraform applies dependencies in the correct order when you use the single `envs/prod` root:

1. **VPC** — networking must exist before the control plane.
2. **ECR** — independent; can be created in parallel with VPC/EKS in practice, but the prod stack declares all modules in one plan.
3. **EKS** — uses `vpc_id` and **private** subnet IDs from the VPC module.

Recommended workflow:

```bash
cd infra/terraform/envs/prod
terraform init -backend=false   # local state; no remote backend configured
terraform plan
terraform apply
```

After apply, configure `kubectl` (e.g. `aws eks update-kubeconfig --name <cluster_name> --region <region>`), deploy Cluster Autoscaler with the IAM role ARN from Terraform output (`cluster_autoscaler_role_arn`), and push images to the ECR URLs from `ecr_repository_urls`.

## State backend

The prod root uses **local state** by default. For anything beyond a personal sandbox, use remote state so state is shared and locked:

- **S3** bucket with versioning and encryption for the state object
- **DynamoDB** table for state locking (optional but recommended)

An example `backend "s3"` block is commented in `envs/prod/versions.tf`. Uncomment it, create the bucket and table once (manually or via a small bootstrap stack), then run `terraform init` to migrate state.

## Monthly cost warning

Even with minimal node counts, **AWS bills for idle infrastructure**:

- **EKS control plane** — roughly **~$0.10/hour per cluster** whether or not pods are running.
- **NAT gateway** — hourly charge plus data processing (this stack uses **one** NAT for cost compromise; it is still a steady line item).
- **EC2 worker nodes** — instance hours for the managed node group.
- **EBS** volumes attached to nodes.

Review [AWS pricing](https://aws.amazon.com/pricing/) and tear down with `terraform destroy` when you are finished experimenting.

## Validation without AWS credentials

Syntax checking does not call AWS APIs:

```bash
cd infra/terraform/envs/prod
terraform init -backend=false
terraform validate
```

`plan` and `apply` require valid credentials and sufficient IAM permissions.