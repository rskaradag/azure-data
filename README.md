# Rabo - Statement Validation

This project implements an end-to-end data validation pipeline on Azure, leveraging **Infrastructure as Code (IaC)** via Terraform and **data processing** with PySpark on Azure Synapse. It includes secure secret management, deployment automation, and API exposure.

---

## 🗍 Architecture Diagram

Add diagram here: `https://github.com/rskaradag/azure-data/blob/main/docs/rabodesign.png`

---

## 📉 Problem Statement

Rabo receives statement records in CSV format, These records must be:

1. ✅ Validated for **unique transaction references**
2. ✅ Validated that **end balance = start balance + mutation**

Invalid records must be logged, and valid ones stored in a database. An API should expose the result.

---

## 🔁 Workflow Summary

1. **CSV Upload:** User uploads CSV to Storage Account (`transactions.csv`)
2. **Synapse Spark Job:** Triggered via Synapse pipeline
3. **Validation:**
   - Duplicated `Reference` check
   - End balance formula check
4. **Result:**
   - Valid records → SQL Database
   - Invalid records → SQL Database + API output
5. **API:** Flask app exposes failed records via REST endpoint

---

## 📊 Infrastructure (via Terraform)

Provisioned using Terraform under `infra/`:

- **Azure Storage Account** (CSV & output)
- **Azure Synapse Workspace + Spark Pool** (Validation)
- **Azure SQL Server + Database** (Valid & Invalid rows)
- **Azure Key Vault** (Secrets like SQL credentials)
- **Azure App Service (Linux)** (Python API)
- **Azure Container Registry** (Holds API Docker image)
- **Role Assignments** (Storage, Key Vault, Synapse access)

---

## 🔐 Secrets & Identity Management

- **Key Vault** stores all SQL secrets: `SQL-SERVER`, `SQL-DB`, `SQL-USER`, `SQL-PASSWORD`
- **Service Principal:** `terraform-sp-rabo` manages IaC
- **System Assigned Managed Identities**:
  - Synapse Workspace (for secret & blob access)
  - App Service (for reading Key Vault at runtime)

---

## ✨ PySpark Validation Script

Located in `notebooks/validate_records.py`. This script:

- Reads CSV from Data Lake (`abfss://...`)
- Casts numeric fields
- Checks for:
  - Duplicated `Reference`
  - Invalid end balances
- Writes valid and invalid rows to SQL DB
- Writes invalid rows to `output/invalid/` folder

---

## 🚀 API Component

- Folder: `api/`
- Language: Python (Flask)
- Containerized with Docker
- Fetches SQL credentials from Key Vault at runtime using `DefaultAzureCredential`
- Exposes:
  - `/invalid` endpoint returning JSON of invalid rows

---

## ♻️ CI/CD (GitHub Actions)

- Triggered on push to `infra/` or `api/`
- Path: `.github/workflows/terraform-ci.yml`
- Executes:
  - `terraform fmt`
  - `terraform validate`
  - `terraform plan`
  - `terraform apply` (only on `main`)
- Supports environments via `infra/tfvars/*.tfvars`
- Supports `workflow_dispatch` for manual runs

---

## 📅 Project Structure

```
.
.
├── api
│   ├── app.py
│   ├── dockerfile
│   ├── requirements.txt
├── docs
│   └── rabodesign.png
├── infra
│   ├── api.tf
│   ├── app.zip
│   ├── data
│   │   └── records.csv
│   ├── main.tf
│   ├── naming.tf
│   ├── notebooks
│   │   └── validate_records.ipynb
│   ├── pipelines
│   │   └── validate_pipeline.json.tpl
│   ├── pyspark
│   │   └── validate_records.py
│   ├── provider.tf
│   ├── outputs.tf
│   ├── resourceNames.tf
│   ├── sql.tf
│   ├── synapse.tf
│   ├── tags.tf
│   ├── templates
│   │   └── spark_config.tmpl
│   ├── tfvars
│   │   └── dev.tfvars
│   ├── variables.tf
│   └── vault.tf
├── README.md
├── requirements.txt


```

---

## 🔢 API Testing Example

```bash
curl https://rabo-exporter.azurewebsites.net/invalid
```

---

## 📊 Requirements

- Terraform >= 1.8.0
- Azure CLI logged in
- GitHub Secrets:
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`
  - `ARM_TENANT_ID`
  - `ARM_SUBSCRIPTION_ID`

---

## 🔧 To Do / Optional Improvements

- Add API pagination & auth
- CI build matrix for `dev`, `staging`, `prod`
- Synapse job scheduling or logic app trigger
- Add monitoring (e.g. App Insights or Log Analytics)

---

Project URL: [https://github.com/rskaradag/azure-data](https://github.com/rskaradag/azure-data)

Feel free to fork or open issues. Contributions welcome!
