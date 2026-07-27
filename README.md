# TipTip Plane Self-Host Hub

This repository contains the deployment automation, infrastructure configuration, proof-of-concept assessment, and data migration toolkit for self-hosting **Plane** on **TipTip's Tencent Cloud infrastructure**.

---

## 📄 Key Repository Documents

* **[`POC_PROPOSAL_PLANE.md`](./POC_PROPOSAL_PLANE.md)**: **Master POC Proposal & Technical Assessment** for TipTip CTO and Engineering Leads. Covers AIAD integration, Jira/Confluence/Linear/ClickUp comparative analysis, token economy advantages, Tencent Cloud cost calculations, and security.
* **[`MIGRATION_GUIDE.md`](./MIGRATION_GUIDE.md)**: Operations manual for bulk exporting Jira tickets and Confluence space packages, detailing migration capabilities and limitations.
* **[`LOCAL_TO_VPS_MIGRATION.md`](./LOCAL_TO_VPS_MIGRATION.md)**: Step-by-step procedure for exporting local PostgreSQL databases (`pg_dump`) and MinIO attachment volumes to the production Tencent Cloud VPS.

---

## ⚡ Quick Start

### 1. Local Development & Testing (macOS / Workstation)
Run Plane locally on Docker Desktop or OrbStack:

```bash
chmod +x deploy-local.sh
./deploy-local.sh
```
Access the application locally:
* **Main Application UI**: `http://localhost/`
* **God Mode Admin Panel**: `http://localhost/god-mode/`

### 2. Production Deployment (TipTip Tencent Cloud VPS)
Run the pre-flight verification and launch script on your server:

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 🛠️ Automated Importer Tools Included

- **[`import_confluence_pages.py`](./import_confluence_pages.py)**: Multi-threaded Python script (`--workers 10`) to parse and upload hundreds of exported Confluence HTML documents to Plane Pages via REST API.
- **[`import_jira_csv_bulk.py`](./import_jira_csv_bulk.py)**: High-speed parallel importer script (`--workers 12`) for importing tens of thousands (`xx,000`) of Jira tickets from CSV into Plane with error logging (`failed_jira_imports.json`).

---

## 📁 Repository Directory Structure

```text
plane-selfhost/
├── README.md                   # Repository hub documentation
├── POC_PROPOSAL_PLANE.md       # Master POC proposal for CTO & Engineering Leadership
├── MIGRATION_GUIDE.md          # Operational guide for Jira & Confluence bulk migration
├── LOCAL_TO_VPS_MIGRATION.md   # Local to VPS database & asset migration guide
├── deploy-local.sh             # Local Docker Desktop/OrbStack setup script
├── deploy.sh                   # Server pre-flight check & setup script for VPS
├── docker-compose.yml          # Unified multi-container Docker Compose specification
├── Caddyfile                   # Nginx / Caddy reverse proxy routing rules
├── .env.example                # Template environment variables file
├── .gitignore                  # Security filter protecting local passwords and logs
├── import_confluence_pages.py  # Parallel Python script for Confluence pages import
└── import_jira_csv_bulk.py     # Parallel Python script for bulk Jira tickets import
```
