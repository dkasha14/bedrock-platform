# 🚀 AI-Driven DevOps RAG Platform for Infrastructure as Code (IaC) using AWS Bedrock

---

## 📌 Project Overview

This project is an enterprise-grade AI-driven DevOps automation platform designed to convert natural language inputs into production-ready, policy-compliant Terraform infrastructure using a Retrieval-Augmented Generation (RAG) architecture.

In real-world enterprise environments, there is always a conflict between speed and compliance. Developers want faster infrastructure provisioning using AI, but organizations require strict adherence to security policies, naming standards, and governance rules. Traditional approaches either rely on manual Terraform development, which is slow and inconsistent, or public AI tools, which are fast but unreliable and risky.

To address this, the system introduces a private RAG-based platform where infrastructure is not generated blindly. Instead, it retrieves approved “Golden Terraform modules” and uses them as the foundation for generation. This ensures consistency, reduces hallucination, and enforces compliance.

The platform integrates with GitHub to create Pull Requests automatically, enabling a GitOps workflow where all infrastructure changes are reviewed before deployment. This balances automation with control.

---

## 🏗️ High-Level Architecture
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

The system follows a structured pipeline where user intent is progressively refined into infrastructure code. When a user submits a request through the UI, it is first handled by the Composer Lambda, which acts as the central orchestrator. Instead of directly calling the LLM, the system performs retrieval to ensure accuracy.

The Retriever Lambda converts the query into embeddings and searches OpenSearch Serverless using hybrid search. Relevant Terraform modules are fetched from S3 and filtered using metadata from DynamoDB. These modules act as the context for generation.

The Composer then injects enterprise policies and builds a structured prompt, which is sent to Bedrock. The generated Terraform code is validated and then pushed to GitHub as a Pull Request, completing the workflow.

🔄 Detailed Data Flow steps
1. User → Flask UI
2. UI → Composer Lambda
3. Composer → Retriever Lambda
4. Retriever → Query → Embedding
5. Retriever → AOSS (KNN + BM25)
6. AOSS → Return Top-K Modules
7. DynamoDB → Metadata Filtering
8. S3 → Fetch Module Content
9. Composer → Inject Policies (SSM)
10. Composer → Build Prompt
11. Prompt → Bedrock (Claude)
12. Bedrock → Generate Terraform
13. Terraform → Validate
14. If Error → Feedback Loop
15. Valid Output → S3
16. S3 → GitHub PR
⏱️ Sequence Diagram
User        UI        Composer      Retriever      AOSS       Bedrock     GitHub
 |           |             |              |            |           |          |
 |---------> |             |              |            |           |          |
 |  Request  |             |              |            |           |          |
 |           | ----------> |              |            |           |          |
 |           |   Invoke    |              |            |           |          |
 |           |             | -----------> |            |           |          |
 |           |             |  Retrieve    | ---------->|           |          |
 |           |             |              |  Query     |           |          |
 |           |             |              |<---------- |           |          |
 |           |             | <----------- |            |           |          |
 |           |             |              |            |           |          |
 |           |             | -----------> |            |           |          |
 |           |             |  Build Prompt            |           |          |
 |           |             | ------------------------>|           |          |
 |           |             |        Send to Bedrock               |          |
 |           |             |<------------------------ |           |          |
 |           |             |   Terraform Output       |           |          |
 |           |             | ---------------------------------------------->|
 |           |             |         Create PR (GitHub)                     |
 |           |             |              |            |           |          |
User → UI → Composer → Retriever → AOSS
Retriever → S3 + DynamoDB → Composer
Composer → Bedrock → Terraform Output
Output → Validation → S3 → GitHub PR
🧱 Architecture Layers
🔷 Infrastructure Layer

The infrastructure layer is designed with a strong focus on security and isolation. All components are provisioned using Terraform, ensuring reproducibility across environments. The system is deployed inside a VPC, and all service interactions happen through VPC endpoints, preventing exposure to the public internet.

From a data flow perspective, user requests enter through the UI and travel securely through Lambda functions into AWS services. IAM roles enforce least privilege access, and KMS encryption ensures data protection at rest.

Data Flow:
User → VPC → Lambda → AWS Services (via private endpoints)

🔷 Data Layer

The data layer combines structured and unstructured storage to enable efficient retrieval. S3 stores Golden Terraform modules, which serve as the source of truth. DynamoDB maintains metadata such as module versions and tags.

OpenSearch Serverless stores embeddings and enables semantic search. During retrieval, both vector similarity and metadata filtering are used together to ensure accurate results.

Data Flow:
S3 → Embedding → AOSS
DynamoDB → Metadata → Filter

🔷 Ingestion Layer

The ingestion pipeline ensures that Terraform modules are continuously updated and indexed. When new modules are added or updated, they are processed through a pipeline that performs semantic chunking.

Each chunk is converted into embeddings using Bedrock and indexed into OpenSearch. Metadata is stored in DynamoDB, ensuring that retrieval remains efficient and context-aware.

Data Flow:
GitHub → Pipeline → Chunking → Embedding → AOSS + DynamoDB

🔷 Retrieval & Generation Layer

This is the core intelligence layer where RAG is implemented. The Retriever Lambda converts user queries into embeddings and retrieves relevant modules from OpenSearch.

The Composer Lambda then builds a structured prompt by combining user input, retrieved modules, and enterprise policies. This prompt is sent to Bedrock, which generates Terraform code grounded in real data.

Data Flow:
User Query → Embedding → AOSS → Modules → Composer → Bedrock

🔷 Application Layer

The application layer provides user interaction and integrates with DevOps workflows. Users interact via a Flask UI, and outputs are automatically converted into GitHub Pull Requests.

This ensures that all generated infrastructure undergoes human review, maintaining control and traceability. Outputs are also stored in S3 for auditing.

Data Flow:
User → UI → Lambda → Output → GitHub PR

⚙️ Commands (End-to-End Execution)
🔷 Terraform Commands
terraform init
terraform validate
terraform plan
terraform apply
🔷 Jenkins Pipeline (CI/CD)
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
🔷 Ingestion Pipeline
python ingestion_pipeline.py
🔷 Run Application
pip install -r requirements.txt
python app.py
🔷 Lambda Deployment
zip function.zip lambda_function.py

aws lambda update-function-code \
  --function-name retriever-lambda \
  --zip-file fileb://function.zip
📈 Business Impact
Reduced provisioning time by ~70%
Improved compliance and standardization
Enabled AI-driven DevOps workflows
Reduced manual errors and inconsistencies
