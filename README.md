# 🚀 AI-Driven DevOps RAG Platform for Infrastructure as Code (IaC) using AWS Bedrock

---

## 📌 Project Overview

This project is an enterprise-grade **AI-driven DevOps automation platform** designed to convert natural language inputs into **production-ready, policy-compliant Terraform infrastructure** using a Retrieval-Augmented Generation (RAG) architecture.

In large-scale environments, teams face a key challenge:  
Developers want the speed of AI, but organizations require strict compliance, security, and standardization. Traditional approaches either rely on manual Terraform development (slow and inconsistent) or public AI tools (fast but unreliable and insecure).

To solve this, this platform introduces a **private, secure RAG pipeline** that retrieves only approved infrastructure modules — referred to as **Golden Modules** — and uses them to guide LLM-based generation. Instead of generating infrastructure blindly, the system ensures that every output is grounded in enterprise-approved templates.

The system integrates directly with GitHub, enabling a GitOps workflow where generated infrastructure is automatically pushed as a Pull Request, ensuring human validation before deployment. This approach significantly improves both speed and governance.

---

## 🏗️ High-Level Architecture (Flow Overview)

User Request → Flask UI → Composer Lambda → Retriever Lambda → AOSS (Vector + BM25 Search) →  
Golden Modules (S3) + Metadata (DynamoDB) → Policy Injection (SSM) → Bedrock (Claude 3.5) →  
Validation Layer → S3 Storage → GitHub PR

---

## 🧭 High-Level Data Flow Diagram
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
```text

User → Flask UI → Composer Lambda → Retriever Lambda → AOSS  
→ (S3 Golden Modules + DynamoDB Metadata)  
→ Composer (Policy Injection via SSM)  
→ Bedrock (Claude 3.5)  
→ Terraform Validate  
→ S3 Storage  
→ GitHub PR
🔄 End-to-End Data Flow (Detailed Explanation)

The system follows a structured flow where each component plays a specific role in transforming user intent into infrastructure code.

When a user submits a request through the UI, the Composer Lambda acts as the entry point and orchestrates the process. Instead of directly invoking the LLM, the system first performs retrieval. The Retriever Lambda converts the query into an embedding and queries OpenSearch Serverless using hybrid search.

This retrieval step ensures that only relevant Golden Modules are fetched. These modules are originally stored in S3 and indexed during the ingestion process. Metadata stored in DynamoDB helps refine results further based on filters like version, environment, or tags.

Once the relevant modules are retrieved, the Composer Lambda injects enterprise policies and constructs a structured prompt. This prompt is then sent to Amazon Bedrock, where the LLM generates Terraform code grounded in the retrieved modules.

Before finalizing the output, the system validates the generated Terraform using terraform validate. If errors are detected, they are fed back into the system for correction. Finally, the validated output is stored in S3 and pushed to GitHub as a Pull Request.

🔄 Detailed Data Flow Diagram (Step-by-Step)
1. User → Flask UI
2. UI → Composer Lambda
3. Composer → Retriever Lambda
4. Retriever → Convert Query → Embedding
5. Retriever → Query AOSS (KNN + BM25)
6. AOSS → Fetch Modules (from S3 indexed data)
7. DynamoDB → Apply Metadata Filters
8. Composer → Inject Policies (SSM)
9. Composer → Build Prompt
10. Prompt → Bedrock (Claude 3.5)
11. Bedrock → Generate Terraform
12. Output → terraform validate
13. If error → feedback loop → Bedrock
14. Valid output → S3
15. S3 → GitHub PR
🧱  SEQUENCE DIAGRAM
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
🔷 1. Infrastructure Layer (Terraform + AWS Services)

The infrastructure layer forms the secure foundation of the entire system. All resources are provisioned using Terraform, ensuring consistency and reproducibility across environments. The system is deployed inside a VPC to enforce strict network isolation, and VPC endpoints are used for services like Bedrock, S3, and OpenSearch to ensure that no data traverses the public internet.

From a data flow perspective, every request initiated from the UI flows through private network channels into Lambda services. These Lambda functions interact with other AWS services securely using IAM roles with least privilege. Encryption is enforced using KMS to protect data at rest, ensuring compliance with enterprise security standards.

Data Flow:
User → VPC → Lambda → VPC Endpoint → AWS Services

🔷 2. Data Layer (S3 + DynamoDB + AOSS)

The data layer is responsible for storing and organizing all knowledge required by the system. S3 acts as the primary storage for Golden Terraform modules, which serve as the source of truth. DynamoDB is used to store metadata such as module version, tags, and environment information, enabling efficient filtering during retrieval.

OpenSearch Serverless (AOSS) is used to store embeddings and perform vector-based search. When data flows into this layer during ingestion, Terraform modules are processed and indexed into AOSS. During runtime, queries from the Retriever Lambda are matched against these embeddings to find semantically relevant modules.

Data Flow:
S3 → Embedding → AOSS
DynamoDB → Metadata Filter → Retrieval

🔷 3. Ingestion Layer (Embedding + Indexing Pipeline)

The ingestion layer is responsible for preparing Terraform modules for retrieval. Whenever modules are updated in GitHub, a Python-based pipeline processes them. Instead of indexing entire files, the system performs semantic chunking, breaking modules into logical units such as resources or configurations.

Each chunk is converted into an embedding using a Bedrock embedding model. These embeddings capture the semantic meaning of the content and are stored in OpenSearch Serverless. Metadata is also attached and stored in DynamoDB to support filtering.

Data Flow:
GitHub → Pipeline → Chunking → Embedding → AOSS + DynamoDB

🔷 4. Retrieval & Generation Layer (Lambda + Bedrock)

This is the core intelligence layer where RAG is implemented. When a user request arrives, the Retriever Lambda converts it into an embedding and queries AOSS to fetch relevant modules. These modules represent the contextual knowledge required for generation.

The Composer Lambda then enriches this context by injecting enterprise policies retrieved from systems like AWS SSM Parameter Store. It constructs a structured prompt that clearly separates user input, retrieved context, and constraints.

This prompt is sent to Amazon Bedrock, where Claude 3.5 Sonnet processes it and generates Terraform code.

Data Flow:
User Query → Embedding → AOSS → Modules → Composer → Bedrock

🔷 5. Application Layer (Flask UI + GitHub Integration)

The application layer provides the interface through which users interact with the system. A Flask-based UI allows users to submit natural language requests, which are then processed by backend services.

From a data flow perspective, user input flows into the Lambda orchestration layer, and the final output flows back as a GitHub Pull Request. This ensures that the system integrates seamlessly with existing DevOps workflows.

Data Flow:
User → UI → Lambda → Output → GitHub PR

⚙️ Commands (Execution Guide)
🔷 Terraform Setup
terraform init
terraform validate
terraform plan
terraform apply
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
🔷 Validation
terraform validate
📈 Business Impact
Reduced infrastructure provisioning time by ~70%
Improved consistency and compliance
Enabled AI-driven DevOps workflows
Reduced manual effort and errors
