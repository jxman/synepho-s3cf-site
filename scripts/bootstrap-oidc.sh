#!/bin/bash
#
# Bootstrap OIDC Provider and GitHub Actions IAM Role
# This script sets up the infrastructure needed for GitHub Actions to authenticate via OIDC
# Run this once locally before deploying via GitHub Actions
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OIDC_URL="https://token.actions.githubusercontent.com"
ROLE_NAME="GithubActionsOIDC-SynephoProject-Role"
POLICY_NAME="GithubActions-SynephoProject-Policy"
GITHUB_REPO="jxman/synepho-s3cf-site"

# Official GitHub OIDC thumbprints
THUMBPRINTS='["6938fd4d98bab03faadb97b34396831e3780aea1","1c58a3a8518e8759bf075b76b750d4f2df264fcd"]'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  GitHub Actions OIDC Bootstrap${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓${NC} AWS Account ID: ${AWS_ACCOUNT_ID}"

# Step 1: Check and create OIDC Provider
echo ""
echo -e "${BLUE}Step 1: OIDC Provider${NC}"
echo -e "Checking if OIDC provider exists for ${OIDC_URL}..."

OIDC_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text 2>/dev/null || echo "")

if [ -z "$OIDC_ARN" ]; then
    echo -e "${YELLOW}⚠${NC}  OIDC provider not found. Creating..."

    OIDC_ARN=$(aws iam create-open-id-connect-provider \
        --url "${OIDC_URL}" \
        --client-id-list "sts.amazonaws.com" \
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" "1c58a3a8518e8759bf075b76b750d4f2df264fcd" \
        --tags Key=Name,Value="GitHub Actions OIDC Provider" Key=ManagedBy,Value="bootstrap-script" \
        --query 'OpenIDConnectProviderArn' \
        --output text)

    echo -e "${GREEN}✓${NC} Created OIDC provider: ${OIDC_ARN}"
else
    echo -e "${GREEN}✓${NC} OIDC provider already exists: ${OIDC_ARN}"
fi

# Step 2: Create IAM Policy
echo ""
echo -e "${BLUE}Step 2: IAM Policy${NC}"
echo -e "Checking if policy ${POLICY_NAME} exists..."

POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" --output text 2>/dev/null || echo "")

if [ -z "$POLICY_ARN" ]; then
    echo -e "${YELLOW}⚠${NC}  Policy not found. Creating..."

    # Create policy document
    cat > /tmp/github-actions-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "cloudfront:*",
        "route53:*",
        "acm:*",
        "cloudwatch:*",
        "logs:*",
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
        "iam:GetOpenIDConnectProvider",
        "iam:CreateOpenIDConnectProvider",
        "iam:UpdateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "dynamodb:*",
        "sts:GetCallerIdentity",
        "ec2:DescribeRegions"
      ],
      "Resource": "*"
    }
  ]
}
EOF

    POLICY_ARN=$(aws iam create-policy \
        --policy-name "${POLICY_NAME}" \
        --description "Policy for GitHub Actions to manage Synepho website Terraform resources" \
        --policy-document file:///tmp/github-actions-policy.json \
        --query 'Policy.Arn' \
        --output text)

    rm /tmp/github-actions-policy.json
    echo -e "${GREEN}✓${NC} Created policy: ${POLICY_ARN}"
else
    echo -e "${GREEN}✓${NC} Policy already exists: ${POLICY_ARN}"
fi

# Step 3: Create IAM Role
echo ""
echo -e "${BLUE}Step 3: IAM Role${NC}"
echo -e "Checking if role ${ROLE_NAME} exists..."

ROLE_ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ]; then
    echo -e "${YELLOW}⚠${NC}  Role not found. Creating..."

    # Create trust policy document
    cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

    ROLE_ARN=$(aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/trust-policy.json \
        --description "Role for GitHub Actions to manage Synepho website infrastructure" \
        --tags Key=Name,Value="GitHub Actions Synepho Project Role" Key=ManagedBy,Value="bootstrap-script" \
        --query 'Role.Arn' \
        --output text)

    rm /tmp/trust-policy.json
    echo -e "${GREEN}✓${NC} Created role: ${ROLE_ARN}"

    # Attach policy to role
    echo -e "Attaching policy to role..."
    aws iam attach-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-arn "${POLICY_ARN}"

    echo -e "${GREEN}✓${NC} Attached policy to role"
else
    echo -e "${GREEN}✓${NC} Role already exists: ${ROLE_ARN}"

    # Verify policy is attached
    ATTACHED=$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --query "AttachedPolicies[?PolicyArn=='${POLICY_ARN}'].PolicyArn" --output text)

    if [ -z "$ATTACHED" ]; then
        echo -e "${YELLOW}⚠${NC}  Policy not attached. Attaching..."
        aws iam attach-role-policy \
            --role-name "${ROLE_NAME}" \
            --policy-arn "${POLICY_ARN}"
        echo -e "${GREEN}✓${NC} Attached policy to role"
    else
        echo -e "${GREEN}✓${NC} Policy already attached to role"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Bootstrap Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✓${NC} OIDC Provider ARN:  ${OIDC_ARN}"
echo -e "${GREEN}✓${NC} IAM Role ARN:       ${ROLE_ARN}"
echo -e "${GREEN}✓${NC} IAM Policy ARN:     ${POLICY_ARN}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. GitHub Actions can now authenticate using OIDC"
echo -e "2. Run: ${YELLOW}gh workflow run \"Terraform Deployment\" -f environment=aws-services${NC}"
echo -e "3. Monitor: ${YELLOW}gh run watch${NC}"
echo ""
