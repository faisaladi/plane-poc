# Jira & Confluence to Plane Migration Guide

This guide details the complete migration workflow for transitioning your team from **Atlassian Jira** and **Confluence** to a self-hosted **Plane** instance.

---

## 1. Executive Summary & Mapping Matrix

Plane is designed as an all-in-one replacement for both project management (Jira) and team documentation (Confluence).

```text
Atlassian Jira                             Self-Hosted Plane
┌────────────────────────────────┐         ┌────────────────────────────────┐
│ Jira Project                   │ ───────►│ Plane Project                  │
│ Jira Issue / Task / Sub-task   │ ───────►│ Plane Issue / Sub-issue        │
│ Jira Epic                      │ ───────►│ Plane Module                   │
│ Jira Sprint                    │ ───────►│ Plane Cycle                    │
│ Jira Issue Status / Workflow   │ ───────►│ Plane State (Backlog, Todo...) │
│ Jira Worklog                   │ ───────►│ Plane Time Estimate & Log      │
└────────────────────────────────┘         └────────────────────────────────┘

Atlassian Confluence                       Self-Hosted Plane
┌────────────────────────────────┐         ┌────────────────────────────────┐
│ Confluence Space               │ ───────►│ Plane Pages (Workspace/Proj)   │
│ Confluence Page & Sub-pages    │ ───────►│ Plane Page & Sub-pages         │
│ Confluence Attachments & Images│ ───────►│ Plane Attachment Assets        │
└────────────────────────────────┘         └────────────────────────────────┘
```

---

## 2. Phase 1: Preparing Your Plane Instance

Before importing data, complete the following prerequisites in Plane:

1. **Deploy Plane & Log In**: Access your instance (e.g., `https://plane.yourcompany.com`).
2. **Access God Mode / Admin**: Ensure your account has Admin privileges in Plane.
3. **Create Target Workspace**: Create the primary workspace where your projects and docs will reside (e.g., `Engineering` or `Company Main`).
4. **Provision User Accounts**:
   * Create accounts for your team members or invite them via email/magic link.
   * Prepare a `users_mapping.csv` file mapping Jira user emails to Plane user emails:
     ```csv
     jira_email,plane_email
     alice@company.com,alice@company.com
     bob@company.com,bob@company.com
     ```

---

## 3. Phase 2: Jira Issues & Projects Migration

Plane includes a native **Jira Importer** accessible directly within your Plane Workspace settings.

### Step 1: Generate Jira API Credentials
* **For Jira Cloud**:
  1. Log into `https://id.atlassian.com/manage-profile/security/api-tokens`.
  2. Click **Create API token** $\rightarrow$ Name it `Plane Migration` $\rightarrow$ Copy the token.
  3. Note your Jira URL (e.g., `https://yourcompany.atlassian.net`) and your Jira admin email address.
* **For Jira Server / Data Center**:
  1. Go to your Profile $\rightarrow$ **Personal Access Tokens**.
  2. Generate a new Personal Access Token (PAT) with read permissions.

### Step 2: Run the Jira Importer in Plane
1. In Plane, navigate to **Workspace Settings** $\rightarrow$ **Imports** $\rightarrow$ **Jira**.
2. Enter your connection credentials:
   * **Jira Domain**: `https://yourcompany.atlassian.net`
   * **Jira Email**: `admin@yourcompany.com`
   * **API Token / PAT**: `[Your API Token]`
3. Click **Connect to Jira**.

### Step 3: Map Projects, States, and Users
1. **Select Projects**: Choose which Jira projects to import (you can import one by one or in batch).
2. **Map Issue States**: Map Jira workflow statuses to Plane state categories:
   * `Backlog` $\rightarrow$ **Backlog**
   * `To Do` $\rightarrow$ **Unstarted**
   * `In Progress` / `In Review` $\rightarrow$ **Started**
   * `Done` / `Closed` $\rightarrow$ **Completed** / **Cancelled**
3. **Map Users**: Upload your `users_mapping.csv` or select equivalent Plane users from the dropdown. Unmapped users will have their issues assigned to the importing Admin.
4. **Start Import**: Click **Import**. Monitor the progress bar. Attachments, comments, sub-tasks, modules (epics), and cycles (sprints) will be processed automatically.

---

### Step 4: High-Volume Bulk Jira Ticket Import (For Tens of Thousands of Tickets)
If you have **tens of thousands (`xx,000`) of tickets** exported from Jira, we have included a high-performance multi-threaded bulk importer script [`import_jira_csv_bulk.py`](./import_jira_csv_bulk.py):

1. Export your Jira tickets to a CSV file (e.g. `jira_export_20000.csv`).
2. Run the bulk script in Terminal:
   ```bash
   python3 import_jira_csv_bulk.py \
     --url "http://localhost" \
     --api-key "your_plane_api_token" \
     --workspace "your-workspace-slug" \
     --project "your-project-id" \
     --csv "jira_export_20000.csv" \
     --workers 12
   ```
   The script parses CSV rows, maps statuses/priorities, and pushes 10–20 tickets per second in parallel into Plane via the REST API with automatic failure logging (`failed_jira_imports.json`).

---

## 4. Phase 3: Confluence Knowledge Base Migration

Plane uses **Plane Pages** as a collaborative document and wiki editor replacing Confluence.

### Step 1: Export Confluence Spaces
1. Open Confluence and navigate to the Space you wish to migrate.
2. Select **Space Settings** (bottom left sidebar) $\rightarrow$ **Space Details / Content Tools**.
3. Select **Export Space**.
4. Choose format: **HTML Export**.
5. Select **Custom Export** $\rightarrow$ Ensure **"Export each item, with attachments"** is checked.
6. Click **Export** and download the resulting `.zip` archive.

### Step 2: Import Selected Pages into Plane Pages

#### Option A: Automated Import via Python Script (Recommended for Multiple Pages)
We have included a ready-to-run automated importer script [`import_confluence_pages.py`](./import_confluence_pages.py) in this repository:

1. Generate an API Key in Plane: Click your avatar (bottom-left) $\rightarrow$ **Profile Settings** $\rightarrow$ **Personal Access Tokens** $\rightarrow$ **Create API Key**.
2. Put your selected exported Confluence `.html` files in a folder (e.g., `./my_selected_docs`).
3. Run the script in Terminal:
   ```bash
   python3 import_confluence_pages.py \
     --url "http://localhost" \
     --api-key "your_plane_api_token" \
     --workspace "your-workspace-slug" \
     --project "your-project-id" \
     --dir "./my_selected_docs"
   ```
   The script extracts page titles, formats HTML content, and creates pages automatically in Plane via the REST API.

#### Option B: Direct Copy-Paste (Recommended for Single / Few Pages)
For a few selected pages:
1. Open the page in Confluence.
2. Highlight & Copy the text/tables/images (`Cmd + C`).
3. Create a new Page in Plane under your Project $\rightarrow$ Paste (`Cmd + V`).
   Plane's rich text editor automatically converts headings, tables, code blocks, lists, and images without formatting loss.

---

## 5. Phase 4: Post-Migration Audit Checklist

After imports finish, run the following verification steps:

- [ ] **Issue Count Audit**: Compare issue count in Jira vs Plane project dashboard.
- [ ] **Attachment Check**: Open 3-5 random imported issues and check attached images/PDFs.
- [ ] **Comments & History Check**: Verify past Jira issue comments appear with proper timestamps and author names.
- [ ] **Modules & Cycles Audit**: Verify Jira Epics migrated to Plane **Modules** and Sprints migrated to Plane **Cycles**.
- [ ] **Wiki Page Hierarchy Check**: Open Plane Pages and verify section titles, formatting, and sub-pages match the original Confluence space layout.
- [ ] **Permissions & Access**: Verify team members can log in, edit assigned tasks, and access workspace pages.
