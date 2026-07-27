#!/usr/bin/env python3
"""
High-Throughput Confluence Selected Pages Importer for Plane (Community Edition)
================================================================================
Designed for importing hundreds/thousands of exported Confluence HTML documents
using multi-threaded parallel HTTP uploads.

Usage:
  python3 import_confluence_pages.py \
    --url "http://localhost" \
    --api-key "your_plane_api_token" \
    --workspace "your-workspace-slug" \
    --project "your-project-id" \
    --dir "./confluence_exports" \
    --workers 10
"""

import os
import sys
import glob
import json
import argparse
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser

class ConfluenceHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.title = ""
        self.in_title = False
        self.body_html = []
        self.in_body = False

    def handle_starttag(self, tag, attrs):
        if tag == "title":
            self.in_title = True
        elif tag == "body":
            self.in_body = True
        elif self.in_body:
            attr_str = " ".join([f'{k}="{v}"' for k, v in attrs])
            self.body_html.append(f"<{tag} {attr_str}>" if attr_str else f"<{tag}>")

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False
        elif tag == "body":
            self.in_body = False
        elif self.in_body:
            self.body_html.append(f"</{tag}>")

    def handle_data(self, data):
        if self.in_title:
            self.title += data
        elif self.in_body:
            self.body_html.append(data)

def parse_html_file(file_path):
    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    parser = ConfluenceHTMLParser()
    parser.feed(content)
    
    title = parser.title.strip() or os.path.basename(file_path).replace(".html", "")
    body_html = "".join(parser.body_html).strip() or content
    return title, body_html

def post_page_to_plane(base_url, api_key, workspace_slug, project_id, filepath):
    title, body_html = parse_html_file(filepath)
    endpoint = f"{base_url.rstrip('/')}/api/v1/workspaces/{workspace_slug}/projects/{project_id}/pages/"
    
    payload = {
        "name": title,
        "description_html": body_html,
        "access": 0
    }

    req = urllib.request.Request(
        endpoint,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "X-API-Key": api_key,
            "Content-Type": "application/json",
            "User-Agent": "Plane-Confluence-Importer/2.0"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            res_data = json.loads(resp.read().decode("utf-8"))
            return True, title, res_data.get("id", "created")
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        return False, title, f"HTTP {e.code}: {error_body}"
    except Exception as e:
        return False, title, str(e)

def main():
    parser = argparse.ArgumentParser(description="Multi-threaded importer for Confluence HTML exports into Plane.")
    parser.add_argument("--url", default="http://localhost", help="Base URL of Plane instance")
    parser.add_argument("--api-key", required=True, help="Plane API Key (Personal Access Token)")
    parser.add_argument("--workspace", required=True, help="Plane Workspace Slug")
    parser.add_argument("--project", required=True, help="Plane Project ID")
    parser.add_argument("--dir", required=True, help="Directory containing Confluence .html files")
    parser.add_argument("--workers", type=int, default=8, help="Number of parallel upload threads (default: 8)")

    args = parser.parse_args()

    html_files = glob.glob(os.path.join(args.dir, "*.html")) + glob.glob(os.path.join(args.dir, "**/*.html"), recursive=True)

    if not html_files:
        print(f"❌ No .html files found in directory: {args.dir}")
        sys.exit(1)

    total_files = len(html_files)
    print(f"🚀 Starting multi-threaded import of {total_files} Confluence page(s) using {args.workers} workers...\n")

    success_count = 0
    failed_count = 0

    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_file = {
            executor.submit(post_page_to_plane, args.url, args.api_key, args.workspace, args.project, filepath): filepath
            for filepath in html_files
        }

        for idx, future in enumerate(as_completed(future_to_file), 1):
            ok, title, result = future.result()
            if ok:
                success_count += 1
                print(f"[{idx}/{total_files}] ✅ Imported: '{title[:40]}...' (ID: {result})")
            else:
                failed_count += 1
                print(f"[{idx}/{total_files}] ❌ Failed: '{title[:40]}...' -> {result}")

    print(f"\n🎉 Import Completed! Successfully imported {success_count}/{total_files} documents ({failed_count} failed).")

if __name__ == "__main__":
    main()
