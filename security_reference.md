# Terraform Security & Best Practices Reference Guide

This document outlines the essential security principles and best practices to ensure that the Terraform Infrastructure as Code (IaC) used for the AWS Landing Zone does not introduce security vulnerabilities or leak sensitive information.

## 1. Secrets Management
- **Never Hardcode Secrets**: Do not store passwords, API keys, or access keys in `.tf` files.
- **Use Secret Stores**: Use AWS Secrets Manager or AWS Systems Manager Parameter Store to manage and retrieve secrets dynamically using `data` sources.
- **Environment Variables**: For provider credentials, rely on environment variables (e.g., `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) or an IAM role (via `AWS_PROFILE` or temporary STS credentials) rather than hardcoding them in the `provider` block.
- **Exclude Variables Files**: Ensure that `terraform.tfvars`, `*.auto.tfvars`, and `.env` files are added to `.gitignore`. If variables are required for a pipeline, inject them at runtime.

## 2. State File Security
- **Remote State**: Store Terraform state in a secure remote backend (e.g., an S3 bucket) rather than locally.
- **State Encryption**: Enable server-side encryption (SSE-S3 or SSE-KMS) on the S3 bucket storing the state files.
- **State Locking**: Use DynamoDB for state locking to prevent concurrent modifications that could corrupt the state.
- **Access Control**: Restrict access to the S3 state bucket and DynamoDB locking table strictly to the IAM roles or users that execute the Terraform pipelines.
- **Never Commit State**: State files can contain plain-text secrets and sensitive infrastructure configurations. They must be strictly git-ignored (`*.tfstate`, `*.tfstate.*`).

## 3. Principle of Least Privilege (IAM)
- **Dedicated Execution Role**: Use a dedicated IAM role for Terraform execution (e.g., via CI/CD) with the minimum necessary permissions. Avoid using administrative (`AdministratorAccess`) credentials.
- **Resource Policies**: Ensure all S3 buckets, KMS keys, and IAM policies created by Terraform explicitly adhere to the principle of least privilege.
- **Audit Logging**: Ensure AWS CloudTrail is enabled for the account to log all API calls made by Terraform.

## 4. Code Security & Analysis
- **Static Application Security Testing (SAST)**: Integrate IaC security scanning tools like **tfsec**, **Checkov**, or **TFLint** into your pre-commit hooks and CI/CD pipelines to detect misconfigurations before deployment.
- **Code Reviews**: Enforce mandatory peer reviews for all Terraform PRs to ensure security standards are met.

## 5. Version Pinning and Dependency Management
- **Pin Providers and Modules**: Strictly pin the versions of all Terraform providers (e.g., `hashicorp/aws = "~> 5.0"`) and remote modules. This prevents upstream changes or compromised provider versions from injecting vulnerabilities.
- **Use Trusted Modules**: Only use well-vetted, official modules (e.g., from the Terraform Registry) and review their source code.

## 6. Secure Resource Configuration
- **Encryption by Default**: Ensure all storage resources (EBS volumes, S3 buckets, RDS databases) created by Terraform enforce encryption at rest.
- **Public Access Blocking**: Use `aws_s3_account_public_access_block` to enforce account-level blocking of public S3 buckets. Avoid assigning public IP addresses to resources unless strictly necessary, and manage access via tight Security Groups.
