# Local-to-VPS Migration Guide for Plane

This document provides a step-by-step guide to migrate your local Plane deployment (running on your laptop/workstation via Docker) to a production VPS when you are ready to upgrade your server host.

---

## Migration Architecture

Moving Plane from Local to VPS requires transferring 3 components:

```text
┌────────────────────────────────────────────────────────┐
│                   LOCAL ENVIRONMENT                    │
│                                                        │
│  1. Database Data  ──►  pg_dump (plane_backup.sql)     │
│  2. Object Uploads ──►  miniodata (tar archive)        │
│  3. Configuration  ──►  .env file                      │
└───────────────────────────┬────────────────────────────┘
                            │ Transfer via SCP / rsync
                            ▼
┌────────────────────────────────────────────────────────┐
│                    VPS ENVIRONMENT                     │
│                                                        │
│  1. Restore Database ──►  pg_restore / psql            │
│  2. Restore Uploads  ──►  Extract to MinIO volume      │
│  3. Update WEB_URL   ──►  https://plane.yourcompany.com│
└────────────────────────────────────────────────────────┘
```

---

## Step 1: Export Data from Local Instance

Run these commands on your local computer in the `plane-selfhost` directory:

### 1. Stop Plane Application Services
Stop application containers to prevent active writes while exporting:

```bash
docker compose stop plane-backend plane-worker plane-web plane-live
```

### 2. Export PostgreSQL Database
Dump all project records, issue details, users, and settings into a single SQL dump:

```bash
docker exec -t plane-db pg_dumpall -U plane_user > plane_db_dump.sql
```

### 3. Archive MinIO File Uploads Volume
Compress all issue attachments, avatars, and doc uploads:

```bash
# Archive the MinIO volume data
docker run --rm \
  -v plane-selfhost_miniodata:/source:ro \
  -v $(pwd):/backup \
  alpine tar -czvf /backup/plane_minio_backup.tar.gz -C /source .
```

### 4. Collect Config & Backup Files
Create a transfer package:
```bash
tar -czvf plane_migration_bundle.tar.gz plane_db_dump.sql plane_minio_backup.tar.gz .env
```

---

## Step 2: Transfer Backup Bundle to VPS

Copy the backup bundle from your laptop to your VPS host:

```bash
scp plane_migration_bundle.tar.gz user@YOUR_VPS_IP:~/
```

---

## Step 3: Restore Data on VPS

Log into your VPS via SSH (`ssh user@YOUR_VPS_IP`) and execute the following:

### 1. Unpack Backup Bundle
```bash
mkdir -p ~/plane-selfhost && cd ~/plane-selfhost
tar -xzvf ~/plane_migration_bundle.tar.gz
```

### 2. Update Environment Configuration for VPS Domain
Edit `.env` and change `WEB_URL` from local to your public VPS domain:

```env
WEB_URL=https://plane.yourcompany.com
PLANE_ENVIRONMENT=production
```

### 3. Start Infrastructure Services on VPS
```bash
docker compose up -d plane-db plane-redis plane-mq plane-minio
```

### 4. Restore PostgreSQL Database
Import the SQL dump into the VPS PostgreSQL database container:

```bash
cat plane_db_dump.sql | docker exec -i plane-db psql -U plane_user -d plane
```

### 5. Restore MinIO File Uploads Volume
Unpack file attachments into the VPS MinIO volume:

```bash
docker run --rm \
  -v plane-selfhost_miniodata:/target \
  -v $(pwd):/backup \
  alpine tar -xzvf /backup/plane_minio_backup.tar.gz -C /target
```

### 6. Start Remaining Application Containers
Launch the rest of Plane microservices:

```bash
docker compose up -d
```

---

## Step 4: Verification Checklist

- [ ] Open `https://plane.yourcompany.com` in your browser.
- [ ] Log in with your existing account credentials created during local testing.
- [ ] Verify projects, issues, cycles, and modules are present.
- [ ] Open an issue with image/file attachments to verify MinIO assets load properly.
- [ ] Test Jira / Confluence imported data in the new production host.
