# security-scanner

Spring Boot security scanner service with EKS, Helm, Trivy Operator, CI security gates, SBOM generation, image signing, and hardened Kubernetes deployment defaults.

## API

Health endpoints are public:

```bash
curl http://localhost:8080/
curl http://localhost:8080/actuator/health
```

Scanner endpoints require `X-API-Key`:

```bash
curl -X POST http://localhost:8080/api/scans \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: change-me' \
  -d '{"target":"registry.example.com/app:latest","type":"container"}'

curl http://localhost:8080/api/scans -H 'X-API-Key: change-me'
```

Set `SCANNER_API_KEY` in production.

## Local Run

```bash
docker compose up --build
```

## Security Tooling

Pull requests run:

- Java tests
- Terraform `fmt`, `init -backend=false`, and `validate`
- TFLint
- Helm lint/render
- Semgrep SARIF upload
- Trivy filesystem and image scans
- Application and image SBOM generation

Deployments scan before push, push immutable ECR tags, sign the pushed digest with Cosign keyless signing, upload an SBOM, and deploy the Helm chart by image digest.

## Terraform

The Terraform stack provisions:

- VPC, ECR, IAM, EKS, and node group
- EKS control-plane audit logging
- Trivy Operator
- EKS managed add-ons for VPC CNI, CoreDNS, kube-proxy, EBS CSI, and CloudWatch observability
- Metrics Server
- AWS Load Balancer Controller
- External Secrets Operator
- Cluster Autoscaler

Use `terraform/backend.tf.example` as the S3/DynamoDB remote state template after creating the state bucket and lock table.

## Required GitHub Secrets and Variables

Secrets:

- `AWS_ROLE_ARN`
- `DB_URL`
- `DB_USERNAME`
- `DB_PASSWORD`
- `SCANNER_API_KEY`

Variables:

- `APP_HOST`
