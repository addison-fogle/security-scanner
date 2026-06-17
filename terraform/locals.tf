locals {
  azs               = ["us-west-2a", "us-west-2b"]
  oidc_provider_url = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
  private_subnets   = ["10.0.3.0/24", "10.0.4.0/24"]
  public_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
}
