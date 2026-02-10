core_region            = "us-east-1"
project                = "dlr-iac-rag"
env                    = "prod"
tags = {
    Owner   = "platform-ai-devops"
    Project = "dlr-iac-rag"
    Env     = "prod"
}

artifacts_bucket       = "dlr-iac-rag-prod-artifacts" # Make sure you are copying name from s3 bucket from infra code
retrieve_lambda_name   = "dlr-iac-rag-prod-retrieve-v2" # Make sure you are copying name from lambda from infra code
bedrock_model_id       = "anthropic.claude-3-5-sonnet-20240620-v1:0"

