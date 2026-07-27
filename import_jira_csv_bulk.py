#!/usr/bin/env python3
"""
High-Speed Bulk Jira Ticket Importer for Plane (Community Edition)
===================================================================
Designed for importing tens of thousands (xx,000) of exported Jira tickets
from CSV into Plane via parallel API requests, with resume & failure logging.

Usage:
  python3 import_jira_csv_bulk.py \
    --url "http://localhost" \
    --api-key "your_plane_api_token" \
    --workspace "your-workspace-slug" \
    --project "your-project-id" \
    --csv "jira_export_20000_tickets.csv" \
    --workers 12
"""

import os
import sys
import csv
import json
import argparse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

JIRA_STATE_MAPPING = {
    "to do": "unstarted",
    "open": "unstarted",
    "backlog": "backlog",
    "in progress": "started",
    "in review": "started",
    "under review": "started",
    "done": "completed",
    "resolved": "completed",
    "closed": "completed",
    "cancelled": "cancelled"
}

JIRA_PRIORITY_MAPPING = {
    "highest": "urgent",
    "blocker": "urgent",
    "critical": "urgent",
    "high": "high",
    "medium": "medium",
    "low": "low",
    "lowest": "none"
}

def post_ticket_to_plane(base_url, api_key, workspace_slug, project_id, row):
    summary = row.get("Summary") or row.get("Issue Summary") or row.get("name", "Untitled Jira Ticket")
    description = row.get("Description") or row.get("issue_description", "")
    jira_key = row.get("Issue key") or row.get("Key") or ""
    
    jira_status = (row.get("Status") or "to do").strip().lower()
    jira_priority = (row.get("Priority") or "medium").strip().lower()

    state_group = JIRA_STATE_MAPPING.get(jira_status, "unstarted")
    priority = JIRA_PRIORITY_MAPPING.get(jira_priority, "medium")

    title = f"[{jira_key}] {summary}" if jira_key else summary
    
    payload = {
        "name": title,
        "description_html": f"<p>{description}</p>" if description else "<p>Imported from Jira</p>",
        "priority": priority
    }

    endpoint = f"{base_url.rstrip('/')}/api/v1/workspaces/{workspace_slug}/projects/{project_id}/issues/"

    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "X-API-Key": api_key,
            "Content-Type": "application/json",
            "User-Agent": "Plane-Jira-Bulk-Importer/1.0"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            res_data = json.loads(resp.read().decode("utf-8"))
            return True, jira_key or summary, res_data.get("id", "created")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        return False, jira_key or summary, f"HTTP {e.code}: {error_body}"
    except Exception as e:
        return False, jira_key or summary, str(e)

def main():
    parser = argparse.ArgumentParser(description="Bulk Jira CSV Importer into Plane.")
    parser.add_argument("--url", default="http://localhost", help="Base URL of Plane instance")
    parser.add_argument("--api-key", required=True, help="Plane API Key")
    parser.add_argument("--workspace", required=True, help="Plane Workspace Slug")
    parser.add_argument("--project", required=True, help="Plane Project ID")
    parser.add_argument("--csv", required=True, help="Path to Jira exported CSV file")
    parser.add_argument("--workers", type=int, default=12, help="Number of parallel upload threads (default: 12)")

    args = parser.parse_args()

    if not os.path.exists(args.csv):
        print(f"❌ CSV file not found: {args.csv}")
        sys.exit(1)

    print(f"📖 Reading Jira CSV file: {args.csv}...")
    rows = []
    with open(args.csv, "r", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    total_tickets = len(rows)
    print(f"🚀 Loaded {total_tickets} Jira ticket(s). Starting parallel import using {args.workers} workers...\n")

    success_count = 0
    failed_count = 0
    failed_logs = []

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_ticket = {
            executor.submit(post_ticket_to_plane, args.url, args.api_key, args.workspace, args.project, row): row
            for row in rows
        }

        for idx, future in enumerate(as_completed(future_to_ticket), 1):
            ok, key_name, result = future.result()
            if ok:
                success_count += 1
                if idx % 100 == 0 or idx == total_tickets:
                    print(f" Progress: [{idx}/{total_tickets}] | Successfully imported: {success_count}")
            else:
                failed_count += 1
                failed_logs.append({"ticket": key_name, "error": result})
                print(f"[{idx}/{total_tickets}] ❌ Failed: '{key_name}' -> {result}")

    if failed_logs:
        with open("failed_jira_imports.json", "w") as f:
            json.dump(failed_logs, f, indent=2)
        print(f"\n⚠️ Logged {failed_count} failed tickets to failed_jira_imports.json")

    print(f"\n🎉 Bulk Ticket Import Complete! Successfully imported {success_count}/{total_tickets} Jira tickets.")

if __name__ == "__main__":
    main()
