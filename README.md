# Phase 2: Cloud Security, DevSecOps & Infrastructure-as-Code Capstone

## 📋 Project Overview
This repository contains the cumulative capstone project deliverables for **Phase 2** of the Cybersecurity Innovation Fellowship at The Knowledge House. The project demonstrates end-to-end cloud infrastructure provisioning, automated governance, container hardening, and incident response engineering within Amazon Web Services (AWS) utilizing **HashiCorp Terraform** and **Python (Boto3)**.

---

## 🛠️ Repository Structure & Labs
* **`TLAB10-Audit/`**: Automated Cloud Governance & Compliance Audit utilizing AWS Config rules (`restricted-ssh` and `s3-bucket-public-read-prohibited`) deployed via Terraform.
* **`TLAB8-Fleet/`**: Container hardening and AWS Elastic Container Registry (ECR) security auditing, utilizing Node.js Alpine Docker images and Python Boto3 scripts for least-privilege IAM policy generation.
* **`TLAB9-Breach/`**: Simulated incident response, threat hunting queries, and postmortem analysis packages.
* **`tlab-05-budgeted-identity/`**: Zero Trust AWS identity management and cost/access controls.
* **`tlab-06-monitored-fortress/`**: Zero Trust VPC architecture featuring isolated subnets, AWS CloudWatch Flow Logs, and SSM Session Manager access.
* **Root Files**: Includes global configuration artifacts, `Dockerfile`, `auditor.py`, `auditor-role.json`, and Terraform state management files.

---

## 🚀 Technologies & Tools Used
* **Cloud & IaC**: Amazon Web Services (AWS VPC, EC2, S3, IAM, AWS Config, ECR, Lambda), HashiCorp Terraform, Docker.
* **Security & Automation**: DevSecOps, Least-Privilege IAM Auditing, Python (Boto3), Git & GitHub Actions.
* **Systems Administration**: Linux Terminal Navigation, Bash Scripting, Incident Response Triage.

---

## 📊 Results & Methodology
1. **Infrastructure as Code:** Provisioned complex multi-tier AWS environments from scratch with zero manual console intervention.
2. **Compliance & Hardening:** Enforced continuous compliance scanning, eliminating external attack vectors and securing container workloads.
3. **Operational Hygiene:** Maintained strict state management lifecycles and reproducible builds, concluding with clean resource teardowns (`terraform destroy`).

---

## 👤 Author
* **Kenneth Cardona** — Cybersecurity Innovation Fellow ([GitHub Profile](https://github.com/kennethcardona07) | [LinkedIn](https://www.linkedin.com/in/kenneth-cardona-49669428b))
