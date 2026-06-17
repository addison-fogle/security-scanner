resource "aws_eks_cluster" "main" {
  name     = "security-scanner-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "eks-node-group-main"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  instance_types = ["t3.medium"]

  tags = {
    "k8s.io/cluster-autoscaler/enabled"                      = "true"
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
  ]
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "kubernetes_namespace" "trivy_operator" {
  metadata {
    name = var.trivy_operator_namespace

    labels = {
      "app.kubernetes.io/name"       = "trivy-operator"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "trivy_operator" {
  name       = "trivy-operator"
  repository = "https://aquasecurity.github.io/helm-charts/"
  chart      = "trivy-operator"
  version    = var.trivy_operator_chart_version
  namespace  = kubernetes_namespace.trivy_operator.metadata[0].name

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      operator = {
        vulnerabilityScannerEnabled          = true
        configAuditScannerEnabled            = true
        rbacAssessmentScannerEnabled         = true
        infraAssessmentScannerEnabled        = true
        exposedSecretScannerEnabled          = true
        clusterComplianceEnabled             = true
        scanJobsConcurrentLimit              = 4
        scanJobTimeout                       = "10m"
        scannerReportTTL                     = "168h"
        metricsFindingsEnabled               = true
        accessGlobalSecretsAndServiceAccount = true
      }
      trivy = {
        severity      = var.trivy_report_severities
        ignoreUnfixed = false
        timeout       = "10m0s"
        slow          = true
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }
      }
      serviceMonitor = {
        enabled = false
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.main,
    kubernetes_namespace.trivy_operator,
  ]
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_oidc_issuer" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
