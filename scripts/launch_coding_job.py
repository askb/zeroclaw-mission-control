#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
##############################################################################
# ZeroClaw PopeBot Job Runner — Ephemeral Coding Agent
#
# Orchestrates: validate repo → clone → aider edit → commit → push → PR
# Usage: launch_coding_job.py "Add dark mode toggle" [repo_url]
##############################################################################

import json
import os
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────

ALLOWLIST_PATH = os.getenv("ALLOWLIST_PATH", "/config/allowed-repos.json")
OUTPUT_DIR = Path(os.getenv("OUTPUT_DIR", "/output"))
WORKSPACE = Path(os.getenv("WORKSPACE", "/workspace"))
GITHUB_PAT = os.getenv("GITHUB_PAT", "")
GITHUB_USER = os.getenv("GITHUB_USER", "askb")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
AIDER_MODEL = os.getenv("AIDER_MODEL", "openrouter/moonshotai/kimi-k2")
TARGET_REPO = os.getenv("TARGET_REPO", "")
JOB_TIMEOUT = int(os.getenv("JOB_TIMEOUT", "1800"))


def load_allowlist() -> dict:
    """Load repo allowlist configuration."""
    try:
        with open(ALLOWLIST_PATH) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"ERROR: Cannot load allowlist: {e}", file=sys.stderr)
        sys.exit(1)


def validate_repo(repo_full_name: str, allowlist: dict) -> bool:
    """Check if repo is in the allowlist. Supports owner/* glob."""
    owner = repo_full_name.split("/")[0] if "/" in repo_full_name else ""

    if repo_full_name in allowlist.get("denied_repos", []):
        return False
    if repo_full_name in allowlist.get("allowed_repos", []):
        return True
    if owner in allowlist.get("allowed_owners", []):
        return True
    return False


def run_cmd(cmd: list, cwd=None, check=True, capture=False) -> subprocess.CompletedProcess:
    """Run a shell command with logging."""
    print(f"  $ {' '.join(cmd)}")
    return subprocess.run(
        cmd, cwd=cwd, check=check,
        capture_output=capture, text=True if capture else None,
    )


def write_status(status: dict):
    """Write job status to output directory for dashboard consumption."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    status_file = OUTPUT_DIR / f"job-{status['job_id']}.json"
    with open(status_file, "w") as f:
        json.dump(status, f, indent=2)
    # Also append to jobs index
    index_file = OUTPUT_DIR / "jobs.json"
    jobs = []
    if index_file.exists():
        try:
            jobs = json.loads(index_file.read_text())
        except (json.JSONDecodeError, ValueError):
            jobs = []
    # Update or append
    jobs = [j for j in jobs if j.get("job_id") != status["job_id"]]
    jobs.insert(0, status)
    # Keep last 100 jobs
    jobs = jobs[:100]
    index_file.write_text(json.dumps(jobs, indent=2))


def main():
    if len(sys.argv) < 2:
        print("Usage: launch_coding_job.py <task> [repo_url_or_name]")
        print("  task: Natural language description of coding task")
        print("  repo: GitHub repo (owner/name or full URL). Defaults to TARGET_REPO env.")
        sys.exit(1)

    task = sys.argv[1]
    repo_arg = sys.argv[2] if len(sys.argv) > 2 else TARGET_REPO

    # Parse repo
    if repo_arg.startswith("https://"):
        repo_full_name = repo_arg.replace("https://github.com/", "").rstrip("/").rstrip(".git")
        repo_url = repo_arg
    elif "/" in repo_arg:
        repo_full_name = repo_arg
        repo_url = f"https://github.com/{repo_arg}.git"
    else:
        print(f"ERROR: Invalid repo: {repo_arg}", file=sys.stderr)
        sys.exit(1)

    job_id = str(uuid.uuid4())[:8]
    branch_name = f"agent-job/{job_id}"
    start_time = datetime.now(timezone.utc)

    status = {
        "job_id": job_id,
        "task": task,
        "repo": repo_full_name,
        "branch": branch_name,
        "status": "started",
        "started_at": start_time.isoformat(),
        "completed_at": None,
        "pr_url": None,
        "pr_number": None,
        "error": None,
        "model": AIDER_MODEL,
        "triggered_by": os.getenv("TRIGGERED_BY", "manual"),
    }

    print(f"🚀 ZeroClaw PopeBot Job {job_id}")
    print(f"   Task: {task}")
    print(f"   Repo: {repo_full_name}")
    print(f"   Branch: {branch_name}")
    print(f"   Model: {AIDER_MODEL}")
    print()

    # ── Step 1: Validate repo against allowlist ──────────────────────────────
    print("📋 Step 1: Validating repo against allowlist...")
    allowlist = load_allowlist()

    if not validate_repo(repo_full_name, allowlist):
        status["status"] = "rejected"
        status["error"] = f"Repository '{repo_full_name}' is not in the write allowlist"
        write_status(status)
        print(f"❌ REJECTED: {status['error']}", file=sys.stderr)
        sys.exit(1)

    print(f"   ✅ Repo '{repo_full_name}' is allowed")

    # ── Step 2: Clone repository ─────────────────────────────────────────────
    print("\n📦 Step 2: Cloning repository...")
    clone_url = repo_url.replace("https://", f"https://x-access-token:{GITHUB_PAT}@")
    repo_dir = WORKSPACE / repo_full_name.split("/")[-1]

    try:
        run_cmd(["git", "clone", "--depth", "50", clone_url, str(repo_dir)])
    except subprocess.CalledProcessError as e:
        status["status"] = "failed"
        status["error"] = f"Clone failed: {e}"
        write_status(status)
        print(f"❌ Clone failed", file=sys.stderr)
        sys.exit(1)

    # ── Step 3: Create feature branch ────────────────────────────────────────
    print(f"\n🌿 Step 3: Creating branch {branch_name}...")
    run_cmd(["git", "checkout", "-b", branch_name], cwd=repo_dir)

    # ── Step 4: Run aider ────────────────────────────────────────────────────
    print(f"\n🤖 Step 4: Running aider with task...")
    status["status"] = "coding"
    write_status(status)

    aider_cmd = [
        "aider",
        "--model", AIDER_MODEL,
        "--no-auto-commits",
        "--yes-always",
        "--no-git",
        "--no-pretty",
        "--no-stream",
        "--message", task,
    ]

    env = os.environ.copy()
    if OPENROUTER_API_KEY:
        env["OPENROUTER_API_KEY"] = OPENROUTER_API_KEY

    try:
        result = subprocess.run(
            aider_cmd, cwd=repo_dir, env=env,
            capture_output=True, text=True,
            timeout=JOB_TIMEOUT,
        )
        print("  aider stdout:", result.stdout[-500:] if len(result.stdout) > 500 else result.stdout)
        if result.returncode != 0:
            print(f"  aider stderr: {result.stderr[-500:]}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        status["status"] = "timeout"
        status["error"] = f"aider timed out after {JOB_TIMEOUT}s"
        write_status(status)
        print(f"❌ Timeout after {JOB_TIMEOUT}s", file=sys.stderr)
        sys.exit(1)

    # ── Step 5: Check for changes ────────────────────────────────────────────
    print("\n🔍 Step 5: Checking for changes...")
    diff_result = run_cmd(
        ["git", "diff", "--stat"], cwd=repo_dir, capture=True, check=False,
    )

    if not diff_result.stdout.strip():
        status["status"] = "no_changes"
        status["error"] = "aider made no changes"
        status["completed_at"] = datetime.now(timezone.utc).isoformat()
        write_status(status)
        print("⚠️  No changes detected — nothing to commit")
        sys.exit(0)

    print(f"  Changes:\n{diff_result.stdout}")

    # ── Step 6: Commit and push ──────────────────────────────────────────────
    print("\n📤 Step 6: Committing and pushing...")
    commit_msg = f"🤖 agent-job/{job_id}: {task[:80]}\n\nAutonomous coding job by ZeroClaw PopeBot.\nTask: {task}\nModel: {AIDER_MODEL}\n\nCo-authored-by: zeroclaw-agent <zeroclaw-agent@noreply.github.com>"

    run_cmd(["git", "add", "-A"], cwd=repo_dir)
    run_cmd(["git", "commit", "-m", commit_msg], cwd=repo_dir)

    try:
        run_cmd(["git", "push", "origin", branch_name], cwd=repo_dir)
    except subprocess.CalledProcessError as e:
        status["status"] = "failed"
        status["error"] = f"Push failed: {e}"
        write_status(status)
        print(f"❌ Push failed", file=sys.stderr)
        sys.exit(1)

    # ── Step 7: Create PR ────────────────────────────────────────────────────
    print("\n📝 Step 7: Creating pull request...")
    pr_title = f"🤖 {task[:60]}"
    pr_body = (
        f"## Autonomous Coding Job\n\n"
        f"**Job ID:** `{job_id}`\n"
        f"**Task:** {task}\n"
        f"**Model:** `{AIDER_MODEL}`\n"
        f"**Branch:** `{branch_name}`\n\n"
        f"---\n"
        f"*Created by ZeroClaw PopeBot — review before merging.*"
    )

    env_gh = os.environ.copy()
    env_gh["GH_TOKEN"] = GITHUB_PAT

    try:
        pr_result = subprocess.run(
            [
                "gh", "pr", "create",
                "--title", pr_title,
                "--body", pr_body,
                "--head", branch_name,
                "--label", "zeroclaw-agent",
            ],
            cwd=repo_dir, capture_output=True, text=True, env=env_gh,
        )
        if pr_result.returncode == 0:
            pr_url = pr_result.stdout.strip()
            status["pr_url"] = pr_url
            # Extract PR number from URL
            if "/pull/" in pr_url:
                status["pr_number"] = int(pr_url.split("/pull/")[-1])
            print(f"  ✅ PR created: {pr_url}")
        else:
            print(f"  ⚠️ gh pr create failed: {pr_result.stderr}")
            status["error"] = f"PR creation failed: {pr_result.stderr[:200]}"
    except Exception as e:
        print(f"  ⚠️ PR creation error: {e}")
        status["error"] = f"PR creation error: {e}"

    # ── Done ─────────────────────────────────────────────────────────────────
    status["status"] = "completed" if status.get("pr_url") else "partial"
    status["completed_at"] = datetime.now(timezone.utc).isoformat()
    write_status(status)

    elapsed = (datetime.now(timezone.utc) - start_time).total_seconds()
    print(f"\n{'✅' if status['status'] == 'completed' else '⚠️'} Job {job_id} finished in {elapsed:.0f}s")
    print(f"   Status: {status['status']}")
    if status.get("pr_url"):
        print(f"   PR: {status['pr_url']}")

    # Output final status as JSON for pipeline consumption
    print(f"\n::JOB_STATUS::{json.dumps(status)}")


if __name__ == "__main__":
    main()
