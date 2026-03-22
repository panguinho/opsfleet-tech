terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"
  name = "eks-karpenter-vpc"
  cidr = var.vpc_cidr
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets  = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i+10)]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = var.tags
}

data "aws_availability_zones" "available" {}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"
  cluster_name    = var.cluster_name
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  enable_irsa     = true
  tags            = var.tags
  eks_managed_node_groups = {
    x86 = {
      instance_types = ["m5.large", "c5.large", "t3.large"]
      min_size     = 1
      max_size     = 5
      desired_size = 1
      capacity_type = "SPOT"
      ami_type = "AL2_x86_64"
      labels = { arch = "amd64" }
    }
    arm = {
      instance_types = ["m6g.large", "c6g.large", "t4g.large"]
      min_size     = 1
      max_size     = 5
      desired_size = 1
      capacity_type = "SPOT"
      ami_type = "AL2_ARM_64"
      labels = { arch = "arm64" }
    }
  }
}

module "karpenter_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "karpenter-controller"
  attach_karpenter_controller_policy = true
  karpenter_controller_cluster_name = module.eks.cluster_name
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
  tags = var.tags
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  namespace  = "karpenter"
  create_namespace = true
  version    = "0.36.2"
  set {
    name  = "controller.clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "controller.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
  set {
    name  = "controller.aws.defaultInstanceProfile"
    value = module.eks.node_iam_instance_profile_name
  }
  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = module.karpenter_irsa.iam_role_arn
  }
  depends_on = [module.eks]
}
