# Terraform Project Automation

## Overview
This repository contains Terraform scripts for provisioning AWS infrastructure (currently VPC and subnets).  
It is designed to be extended in the future for EC2, RDS, and more complex setups.

The workflow uses **GitHub Actions** for CI/CD, primarily for code versioning and logging. Terraform commands (`init`, `plan`, `apply`) are executed locally for now.

---

## Folder Structure

Terraform-automation/
│
├── main.tf # Terraform resources
├── variables.tf # Terraform variables
├── terraform.tfvars # Local environment-specific values (ignored in repo)
├── .github/
│ └── workflows/
│ └── terraform.yml # GitHub Actions workflow
└── README.md


> **Note:** `terraform.tfvars` contains sensitive data and should **not** be committed. Add it to `.gitignore`.

---

## Managing Sensitive Variables

Since `.tfvars` contains secrets (AWS keys, subnet CIDRs, etc.), it is **encrypted and stored as a GitHub secret** using Base64 encoding.

### Steps to encode your `.tfvars` (Windows PowerShell)

```powershell
# Encode terraform.tfvars as base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("terraform.tfvars")) | Out-File -Encoding ascii encoded.txt
Copy the output from encoded.txt

Create a GitHub secret: TF_VARS_B64 and paste the Base64 string

Decode in GitHub Actions workflow
- name: Decode tfvars file
  run: |
    echo "${{ secrets.TF_VARS_B64 }}" | base64 --decode > terraform.tfvars

This preserves all quotes, newlines, and formatting, ensuring the file is parsed correctly by Terraform.

GitHub Actions Workflow

Current workflow only prints a summary when code is pushed, Terraform init and plan are commented out for now.

name: Terraform CI

on:
  push:
    branches:
      - main

jobs:
  summary:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Summary
        run: |
          echo "✅ Terraform code pushed successfully"
          echo "💬 Commit message: ${{ github.event.head_commit.message }}"


Running Terraform Locally

Since CI/CD plan/apply is disabled, run Terraform locally:

terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"

