output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR repository URL for pushing images"
}

output "ecr_repository_name" {
  value       = aws_ecr_repository.app.name
  description = "ECR repository name"
}

output "aws_region" {
  value       = var.aws_region
  description = "AWS region"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM role ARN for GitHub Actions OIDC"
}

output "trivy_operator_namespace" {
  value       = kubernetes_namespace.trivy_operator.metadata[0].name
  description = "Namespace where Trivy Operator is installed"
}
