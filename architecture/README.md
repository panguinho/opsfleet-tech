# Innovate Inc. Cloud Architecture Design

## Overview
This document proposes a robust, scalable, secure, and cost-effective AWS-based architecture for Innovate Inc.'s web application, leveraging managed Kubernetes (EKS), PostgreSQL, and best practices for cloud-native deployments.

---

## 1. Cloud Environment Structure
- **Accounts:**
  - **3 AWS Accounts:**
    - `prod`: Production workloads
    - `staging`: Pre-production/testing
    - `shared-services`: CI/CD, monitoring, IAM, networking
  - **Justification:**
    - Security isolation, cost tracking, and least-privilege access.
    - Follows AWS best practices (multi-account strategy).

---

## 2. Network Design
- **VPC per environment** (prod, staging)
- **Subnets:**
  - Public (load balancers, NAT)
  - Private (EKS nodes, app pods)
  - Isolated (databases)
- **Security:**
  - Security groups, NACLs, no direct public DB access
  - Private endpoints for S3, RDS, ECR
  - VPC Flow Logs enabled

---

## 3. Compute Platform (EKS)
- **EKS for Kubernetes:**
  - Managed node groups (x86, arm64)
  - Karpenter for autoscaling
  - Spot and On-Demand mix
- **Scaling:**
  - HPA for pods, Karpenter for nodes
- **Resource Allocation:**
  - Resource requests/limits, taints/labels for workloads
- **Containerization:**
  - Images built via CI/CD (GitHub Actions, CodeBuild)
  - Images stored in ECR
  - Automated deployments via ArgoCD (personal preference), but Flux is also a viable alternative

---

## 4. Database
- **Service:** Amazon RDS for PostgreSQL (Multi-AZ)
- **Backups:** Automated daily snapshots, PITR enabled
- **High Availability:** Multi-AZ, automatic failover
- **Disaster Recovery:** Cross-region snapshots, regular DR drills

---


---

## 5. Observability
- Datadog is recommended for monitoring, metrics, and logs (alternatives: AWS CloudWatch, Prometheus/Grafana)

---

## 6. High-Level Architecture Diagram

```mermaid
flowchart TB
  %% Environments
  subgraph Accounts
    Prod
    Staging
    Shared
  end

  subgraph PublicLayer
    User
    ALB
  end

  subgraph VPC
    subgraph PublicSubnet
      ALB
    end
    subgraph PrivateSubnet
      EKS
      NodeX86
      NodeARM
      Karpenter
      subgraph Workloads
        FE
        BE
      end
    end
    subgraph IsolatedSubnet
      RDS
    end
  end

  subgraph DataLayer
    S3
    ECR
    Secrets
  end

  subgraph CICD_Observability
    CI
    Datadog
  end

  User --> ALB
  ALB --> FE
  FE --> BE
  FE -.-> EKS
  BE -.-> EKS
  EKS --> NodeX86
  EKS --> NodeARM
  NodeX86 -.-> Karpenter
  NodeARM -.-> Karpenter
  BE --> RDS
  BE --> S3
  EKS --> ECR
  EKS --> Secrets
  CI --> ECR
  CI --> EKS
  RDS -->|Backups| S3
  EKS --> Datadog
  NodeX86 --> Datadog
  NodeARM --> Datadog
  FE -.-> Datadog
  BE -.-> Datadog
  Prod --> VPC
  Staging --> VPC
  Shared --> CICD_Observability
```

---

## 7. Security Best Practices
- IAM least privilege
- Secrets in AWS Secrets Manager
- Encryption in transit and at rest
- Audit logging (CloudTrail, GuardDuty)

---

## 8. Cost Optimization
- Use of Spot instances
- Rightsizing, auto-scaling
- Scheduled scaling for off-hours
- Monitor with AWS Cost Explorer

---

## 9. CI/CD
- GitHub Actions triggers build/test/deploy
- ArgoCD/Flux for GitOps deployment
- Automated rollbacks and notifications
