variable "aws_load_balancer_controller_chart_version" {
  type        = string
  description = "AWS Load Balancer Controller Helm chart version"
  default     = "1.8.3"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the security scanner infrastructure"
  default     = "us-west-2"
}

variable "cluster_autoscaler_chart_version" {
  type        = string
  description = "Cluster Autoscaler Helm chart version"
  default     = "9.37.0"
}

variable "enable_aws_load_balancer_controller" {
  type        = bool
  description = "Install AWS Load Balancer Controller"
  default     = true
}

variable "enable_cluster_autoscaler" {
  type        = bool
  description = "Install Kubernetes Cluster Autoscaler"
  default     = true
}

variable "enable_eks_addons" {
  type        = bool
  description = "Install common EKS managed add-ons"
  default     = true
}

variable "enable_external_secrets" {
  type        = bool
  description = "Install External Secrets Operator"
  default     = true
}

variable "enable_metrics_server" {
  type        = bool
  description = "Install Kubernetes Metrics Server"
  default     = true
}

variable "enable_observability_addon" {
  type        = bool
  description = "Install the Amazon CloudWatch Observability EKS add-on"
  default     = true
}

variable "external_secrets_chart_version" {
  type        = string
  description = "External Secrets Operator Helm chart version"
  default     = "0.10.7"
}

variable "trivy_operator_chart_version" {
  type        = string
  description = "Trivy Operator Helm chart version"
  default     = "0.33.1"
}

variable "trivy_operator_namespace" {
  type        = string
  description = "Kubernetes namespace for Trivy Operator"
  default     = "trivy-system"
}

variable "trivy_report_severities" {
  type        = string
  description = "Comma-separated vulnerability severities reported by Trivy"
  default     = "UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL"
}
