# storing db password in secrets manager instead of hardcoding anywhere
# app fetches it at runtime — nothing sensitive in the codebase
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}/db-password/${var.environment}"
  description = "RDS PostgreSQL password for nexcloud app"

  # 7 day recovery window — gives us time to restore if accidentally deleted
  recovery_window_in_days = 7

  tags = {
    Name        = "${var.project_name}-db-password-${var.environment}"
    Environment = var.environment
  }
}

# actual password value — terraform marks this sensitive so it never prints
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# IAM role for app pods to access secrets — same pattern as GCP service account
resource "aws_iam_role" "nexcloud_app_role" {
  name = "${var.project_name}-app-role-${var.environment}"

  # only pods in our EKS cluster can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      }
    ]
  })
}

# OIDC provider — lets EKS pods assume IAM roles securely without static keys
# thumbprint is the SHA1 of the AWS OIDC root CA certificate —
# rarely changes but should be verified if OIDC authentication breaks
# https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.nexcloud_eks.identity[0].oidc[0].issuer
}

# policy allowing app role to read secrets — nothing more
resource "aws_iam_role_policy" "app_secrets_policy" {
  name = "${var.project_name}-secrets-policy-${var.environment}"
  role = aws_iam_role.nexcloud_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}