## 🧭 High-Level Data Flow

The system follows a structured pipeline where user intent is progressively transformed into infrastructure code in a controlled and secure manner.  

When a user submits a request through the Flask UI, the request is first handled by the Composer Lambda, which acts as the orchestration layer. Instead of directly invoking the LLM, the system performs a retrieval step to ensure that the generation is grounded in enterprise-approved data.  

The Retriever Lambda converts the user query into embeddings and performs a hybrid search (vector + BM25) in OpenSearch Serverless (AOSS). It retrieves relevant "Golden Terraform modules" stored in S3 and refines results using metadata from DynamoDB.  

The Composer then injects enterprise policies and constructs a structured prompt, which is sent to AWS Bedrock (Claude 3.5 Sonnet). The generated Terraform output is validated and stored in S3, and finally pushed to GitHub as a Pull Request for review.

---

## 🔄 Data Flow Diagram

```text
User (Flask UI)
      |
      v
Composer Lambda (Orchestrator)
      |
      v
Retriever Lambda (Embedding + Search)
      |
      v
OpenSearch (AOSS - Vector + BM25)
      |
      v
S3 (Golden Modules) + DynamoDB (Metadata)
      |
      v
Composer Lambda (Prompt + Policy Injection)
      |
      v
AWS Bedrock (Claude 3.5 Sonnet)
      |
      v
Terraform Validate
      |
      v
S3 (Artifacts Storage)
      |
      v
GitHub PR (GitOps Workflow)
🔁 Detailed Data Flow Steps
User submits request via Flask UI
Request is forwarded to Composer Lambda
Composer invokes Retriever Lambda
Query is converted into embedding
Retriever queries AOSS (vector + BM25 search)
Relevant modules are fetched from S3
Metadata filtering applied using DynamoDB
Composer injects enterprise policies (SSM)
Structured prompt is constructed
Prompt is sent to AWS Bedrock
Terraform code is generated
Code is validated using terraform validate
If validation fails → feedback loop to LLM
Valid output stored in S3
GitHub PR is created for review
⏱️ Sequence Flow
User → UI → Composer → Retriever → AOSS
Retriever → S3 + DynamoDB → Composer
Composer → Bedrock → Terraform Output
Output → Validation → S3 → GitHub PR
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
