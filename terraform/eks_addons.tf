resource "aws_eks_addon" "core" {
  for_each = var.enable_eks_addons ? toset([
    "vpc-cni",
    "coredns",
    "kube-proxy",
  ]) : toset([])

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_eks_addons ? 1 : 0
  name  = "security-scanner-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count      = var.enable_eks_addons ? 1 : 0
  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_eks_addons ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi[0].arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi,
  ]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_observability_addon ? 1 : 0

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300

  values = [
    yamlencode({
      installCRDs = true
    })
  ]

  depends_on = [aws_eks_node_group.main]
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  name  = "security-scanner-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  name  = "security-scanner-aws-load-balancer-controller"
  role  = aws_iam_role.aws_load_balancer_controller[0].id

  policy = file("${path.module}/policies/aws-load-balancer-controller.json")
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_load_balancer_controller_chart_version
  namespace  = "kube-system"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 600

  values = [
    yamlencode({
      clusterName = aws_eks_cluster.main.name
      region      = var.aws_region
      vpcId       = aws_vpc.main.id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller[0].arn
        }
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy.aws_load_balancer_controller,
  ]
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "security-scanner-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "security-scanner-cluster-autoscaler"
  role  = aws_iam_role.cluster_autoscaler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"                      = "true"
            "aws:ResourceTag/k8s.io/cluster-autoscaler/${aws_eks_cluster.main.name}" = "owned"
          }
        }
      }
    ]
  })
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version
  namespace  = "kube-system"

  atomic          = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = aws_eks_cluster.main.name
      }
      awsRegion = var.aws_region
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
          }
        }
      }
      extraArgs = {
        "balance-similar-node-groups"   = "true"
        "skip-nodes-with-system-pods"   = "false"
        "skip-nodes-with-local-storage" = "false"
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy.cluster_autoscaler,
  ]
}
