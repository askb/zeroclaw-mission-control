#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
"""Dump GitHub + Gerrit review data for the ZeroClaw dashboard."""

import json
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(os.environ.get("ZEROCLAW_DIR", os.path.expanduser("~/git/github/zeroclaw-mission-control")))
SECRETS = json.loads((BASE / "config/gateway/secrets.json").read_text())
OUT = BASE / "data/reviews/reviews.json"
OUT.parent.mkdir(parents=True, exist_ok=True)

UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) ZeroClaw-Dashboard/1.0"
GERRIT = "https://git.opendaylight.org/gerrit"
GITHUB = "https://api.github.com"
GH_TOKEN = SECRETS.get("GITHUB_RO_TOKEN", "")
GERRIT_USER = SECRETS.get("GERRIT_HTTP_USER", "askb")


def gerrit_get(query: str) -> list:
    url = f"{GERRIT}/changes/?q={query}&n=30"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            text = resp.read().decode()
            return json.loads(text.lstrip(")]}'\\n"))
    except Exception as e:
        print(f"  Gerrit query failed ({query[:60]}): {e}", file=sys.stderr)
        return []


def github_get(endpoint: str):
    url = f"{GITHUB}{endpoint}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {GH_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": UA,
    })
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        print(f"  GitHub query failed ({endpoint[:60]}): {e}", file=sys.stderr)
        return {"items": []}


print("Fetching Gerrit data...")
my_changes = gerrit_get(f"status:open+owner:{GERRIT_USER}")
print(f"  My open changes: {len(my_changes)}")
reviewer_changes = gerrit_get(f"status:open+reviewer:{GERRIT_USER}")
print(f"  Pending reviews: {len(reviewer_changes)}")
merged = gerrit_get("status:merged+-age:1d+(project:releng/builder+OR+project:releng/global-jjb)")
print(f"  Recently merged: {len(merged)}")

print("Fetching GitHub data...")
incoming = github_get("/search/issues?q=is:pr+is:open+review-requested:askb+archived:false&per_page=30&sort=updated")
print(f"  Incoming PRs: {incoming.get('total_count', 0)}")
my_prs = github_get("/search/issues?q=is:pr+is:open+author:askb+archived:false&per_page=30&sort=updated")
print(f"  My open PRs: {my_prs.get('total_count', 0)}")

# Failed workflows (check key repos)
failed_runs = []
for repo in ["askb/zeroclaw-mission-control", "askb/zeroclaw-dashboard", "askb/askb-ha-config",
             "askb/packer-build-action", "askb/lfreleng-actions"]:
    data = github_get(f"/repos/{repo}/actions/runs?status=failure&per_page=5")
    for run in data.get("workflow_runs", []):
        failed_runs.append(run)
print(f"  Failed workflows: {len(failed_runs)}")

data = {
    "source": "live",
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "gerrit_raw": {
        "my_changes": my_changes,
        "pending_reviews": reviewer_changes,
        "recently_merged": merged,
    },
    "github_raw": {
        "incoming_prs": incoming.get("items", []),
        "my_prs": my_prs.get("items", []),
        "failed_workflows": failed_runs,
    },
}

OUT.write_text(json.dumps(data, indent=2))
print(f"Written to {OUT} ({OUT.stat().st_size} bytes)")
