# AWS Infrastructure Dashboard Environment Configuration
site_name        = "aws-services.synepho.com"
environment      = "aws-services"
primary_region   = "us-east-1"
secondary_region = "us-west-1"
hosted_zone_name = "synepho.com" # Parent domain for Route53 hosted zone

# CORS configuration for data file access
enable_cors = true
cors_allowed_origins = [
  "https://aws-services.synepho.com",
  "https://www.aws-services.synepho.com",
  "http://localhost:3000",
  "http://localhost:3002"
]

# Lambda data fetcher permissions
data_fetcher_lambda_role_arn = "arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h"
