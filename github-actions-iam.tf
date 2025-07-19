# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.common_tags, {
    Name = "GitHub Actions OIDC Provider"
  })
}

# IAM Role for GitHub Actions OIDC
resource "aws_iam_role" "github_actions_role" {
  name = "GithubActionsOIDCTerraformRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:jxman/synepho-s3cf-site:*"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "GitHub Actions Terraform Role"
  })
}

# IAM Policy for GitHub Actions with all required permissions
resource "aws_iam_policy" "github_actions_policy" {
  name        = "GithubActionsTerraformPolicy"
  description = "Policy for GitHub Actions to manage Terraform resources including CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # S3 permissions for state and website buckets
          "s3:*",

          # CloudFront permissions
          "cloudfront:*",

          # Route53 permissions
          "route53:*",

          # ACM permissions
          "acm:*",

          # CloudWatch permissions for monitoring
          "cloudwatch:*",

          # CloudWatch Logs permissions
          "logs:*",

          # IAM permissions for service roles
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:PassRole",

          # DynamoDB for state locking
          "dynamodb:*",

          # General permissions
          "sts:GetCallerIdentity",
          "ec2:DescribeRegions"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}