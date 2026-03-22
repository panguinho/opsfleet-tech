# Opsfleet EKS + Karpenter Terraform POC

This Terraform module deploys an AWS EKS cluster with Karpenter for advanced autoscaling, supporting both x86 and Graviton (arm64) Spot and On-Demand instances in a dedicated VPC.

## Features
- Latest EKS version
- Dedicated VPC
- Karpenter autoscaler
- Node pools for x86 and arm64 (Graviton) Spot/On-Demand

## Usage

1. Install [Terraform](https://www.terraform.io/downloads.html) and configure your AWS credentials.
2. Initialize and apply the Terraform code:
   ```sh
   terraform init
   terraform apply
   ```
3. After apply, update your kubeconfig:
   ```sh
   aws eks update-kubeconfig --region <region> --name <cluster_name>
   ```
4. To schedule a pod on a specific architecture, use the following nodeSelector in your pod spec:
   - For x86:
     ```yaml
     nodeSelector:
       kubernetes.io/arch: amd64
     ```
   - For Graviton (arm64):
     ```yaml
     nodeSelector:
       kubernetes.io/arch: arm64
     ```

## Notes
- Karpenter is installed via Helm.
- IAM roles and policies for Karpenter are provisioned automatically.
- See main.tf for all configurable variables.
