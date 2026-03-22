output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "karpenter_irsa_role_arn" {
  value = module.karpenter_irsa.iam_role_arn
}
