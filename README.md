**# 🚀 AI-Driven DevOps RAG Platform for Infrastructure as Code (IaC) using AWS Bedrock

---

## 📌 Project Overview

This project is an enterprise-grade AI-driven DevOps platform that converts natural language requests into production-ready, policy-compliant Terraform infrastructure using a Retrieval-Augmented Generation (RAG) architecture.

In enterprise environments, there is always a trade-off between speed and compliance. Developers need fast infrastructure provisioning, while organizations require strict governance, security, and standardization. Traditional approaches either rely on manual Terraform development, which is slow and inconsistent, or public AI tools, which are fast but unreliable.

To solve this, the platform introduces a private RAG pipeline that retrieves only approved “Golden Terraform modules” and uses them to guide LLM-based generation. This ensures outputs are secure, standardized, and compliant.

The system integrates with GitHub to automatically create Pull Requests, enabling a GitOps workflow with human validation before deployment.

---

## 🏗️ High-Level Architecture (Mermaid)

                    +----------------------+
                    |      User (UI)       |
                    |     Flask App        |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |  Composer Lambda     |
                    | (Orchestration Layer)|
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |  Retriever Lambda    |
                    | (Embedding + Search) |
                    +----------+-----------+
                               |
         -------------------------------------------------
         |                                               |
         v                                               v
+----------------------+                    +----------------------+
|  OpenSearch (AOSS)   |                    |   DynamoDB           |
|  Vector + BM25       |                    |   Metadata Store     |
+----------+-----------+                    +----------+-----------+
           |                                               |
           v                                               v
                    +----------------------+
                    |     S3 Bucket        |
                    |  Golden Modules      |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |   Composer Lambda    |
                    | (Prompt + Policies)  |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |   AWS Bedrock        |
                    | Claude 3.5 Sonnet    |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    | Terraform Validation |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |   S3 (Artifacts)     |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |   GitHub PR          |
                    |   (GitOps Flow)      |
                    +----------------------+
🔄 High-Level Data Flow

The system follows a structured pipeline where user intent is progressively transformed into infrastructure code. When a user submits a request through the UI, it is first handled by the Composer Lambda, which acts as the orchestrator.

Instead of directly calling the LLM, the system performs retrieval using the Retriever Lambda. The query is converted into embeddings and searched against OpenSearch Serverless using hybrid search. Relevant modules are fetched from S3 and filtered using metadata from DynamoDB.

The Composer then injects enterprise policies and builds a structured prompt, which is sent to Bedrock. The generated Terraform is validated and pushed to GitHub as a Pull Request.

🔄 Detailed Data Flow steps

1. User submits request via Flask UI
2. Request is sent to Composer Lambda
3. Composer invokes Retriever Lambda
4. Retriever converts query → embedding
5. Retriever queries AOSS (vector + BM25)
6. AOSS returns top-k relevant modules
7. Metadata is fetched from DynamoDB
8. Modules are fetched from S3
9. Composer injects enterprise policies (SSM)
10. Composer builds structured prompt
11. Prompt sent to Bedrock
12. Bedrock generates Terraform code
13. Code validated using terraform validate
14. If error → feedback loop to Bedrock
15. Final output stored in S3
16. GitHub PR created for review
🧱 Architecture Layers
🔷 Infrastructure Layer

The infrastructure layer is designed with a strong focus on security, isolation, and reproducibility. All resources are provisioned using Terraform, ensuring consistency across environments. The system runs inside a VPC, and all AWS services are accessed via VPC endpoints, preventing exposure to the public internet.

From a data flow perspective, requests enter through the UI and move securely through Lambda services. IAM roles enforce least privilege access, and KMS encryption protects data at rest.

Data Flow:
User → VPC → Lambda → AWS Services

🔷 Data Layer

The data layer combines multiple storage systems to support both structured and unstructured data. S3 stores Golden Terraform modules, which act as the source of truth. DynamoDB stores metadata such as version, tags, and configurations.

OpenSearch Serverless enables semantic retrieval using embeddings. During runtime, both vector search and metadata filtering work together to ensure accurate results.

Data Flow:
S3 → Embeddings → AOSS
DynamoDB → Metadata → Filter

🔷 Ingestion Layer

The ingestion pipeline processes Terraform modules whenever updates occur. It performs semantic chunking to break files into logical units and generates embeddings using Bedrock.

These embeddings are indexed into OpenSearch, while metadata is stored in DynamoDB. This ensures the system always retrieves updated and relevant data.

Data Flow:
GitHub → Pipeline → Chunking → Embedding → AOSS + DynamoDB

🔷 Retrieval & Generation Layer

This layer implements the RAG pipeline. The Retriever Lambda converts queries into embeddings and retrieves relevant modules. The Composer Lambda builds a structured prompt using retrieved modules and policies.

This prompt is sent to Bedrock, which generates Terraform code grounded in enterprise-approved modules.

Data Flow:
Query → Embedding → AOSS → Modules → Composer → Bedrock

🔷 Application Layer

The application layer enables user interaction and integrates with DevOps workflows. Users submit requests through a Flask UI, and outputs are automatically converted into GitHub Pull Requests.

This ensures that all generated infrastructure is reviewed before deployment, maintaining control and traceability.

Data Flow:
User → UI → Lambda → Output → GitHub PR

⚙️ Commands
🔷 Terraform 
terraform init
terraform validate
terraform plan
terraform apply
🔷 Jenkins Pipeline
pipeline {
  agent any
  stages {
    stage('Checkout') {
      steps { git 'repo-url' }
    }
    stage('Terraform Init') {
      steps { sh 'terraform init' }
    }
    stage('Terraform Plan') {
      steps { sh 'terraform plan' }
    }
    stage('Terraform Apply') {
      steps { sh 'terraform apply -auto-approve' }
    }
  }
}
🔷 Ingestion
python ingestion_pipeline.py
🔷 Run App
pip install -r requirements.txt
python app.py
🔷 Lambda Deploy
zip function.zip lambda_function.py

aws lambda update-function-code \
  --function-name retriever-lambda \
  --zip-file fileb://function.zip
📈 Business Impact
Reduced provisioning time by ~70%
Improved compliance and standardization
Enabled AI-driven DevOps workflows
Reduced manual errors
📌 Conclusion

This platform demonstrates how AI and DevOps can be combined to build a scalable, secure, and intelligent infrastructure automation system. It enables organizations to achieve speed without compromising governance.**
