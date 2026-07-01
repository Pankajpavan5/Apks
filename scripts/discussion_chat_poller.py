#!/usr/bin/env python3
"""
discussion_chat_poller.py

Polls a GitHub Discussion for new comments every 5 seconds for 2 minutes (default).
Designed for AIOS agents to monitor discussion chat threads without a browser.

Usage:
    export GITHUB_PAT="your_token_here"
    python3 scripts/discussion_chat_poller.py <owner> <repo> <discussion_number> [duration_seconds] [interval_seconds]

Example:
    export GITHUB_PAT="ghp_xxx"
    python3 scripts/discussion_chat_poller.py Pankajpavan5 Apks 2 120 5

Parameters:
    owner               GitHub repository owner
    repo                GitHub repository name
    discussion_number   Discussion number from the URL
    duration_seconds    Total polling time (default: 120 = 2 minutes)
    interval_seconds   Seconds between polls (default: 5)
"""

import os
import sys
import time
import json
import datetime
from typing import Optional

try:
    import requests
except ImportError:
    print("Error: requests library not installed. Run: pip install requests")
    sys.exit(1)


def get_env_pat() -> Optional[str]:
    """Get PAT from environment. Never use hardcoded tokens."""
    return os.environ.get("GITHUB_PAT")


def fetch_comments(owner: str, repo: str, discussion_number: int, pat: Optional[str]) -> list:
    """Fetch discussion comments from GitHub API."""
    url = f"https://api.github.com/repos/{owner}/{repo}/discussions/{discussion_number}/comments"
    headers = {"Accept": "application/vnd.github+json"}
    if pat:
        headers["Authorization"] = f"token {pat}"
    try:
        resp = requests.get(url, headers=headers, timeout=15)
        if resp.status_code == 200:
            return resp.json()
        elif resp.status_code == 401:
            print(f"[Error] Authentication failed (401). PAT may be invalid or expired.")
            return []
        elif resp.status_code == 403:
            print(f"[Error] Rate limited or forbidden (403). Check PAT scopes.")
            return []
        else:
            print(f"[Error] Failed to fetch comments: HTTP {resp.status_code}")
            print(resp.text[:500])
            return []
    except Exception as e:
        print(f"[Error] Network exception: {e}")
        return []


def format_comment(comment: dict) -> str:
    """Format a comment in a chat-like style."""
    author = comment.get("user", {}).get("login", "unknown")
    created = comment.get("created_at", "unknown")
    body = comment.get("body", "")
    # Shorten body for chat display
    lines = body.strip().split("\n")
    preview = " ".join(lines[:3])[:200]
    if len(body) > 200:
        preview += " ..."
    return f"[{created}] {author}: {preview}"


def post_comment(owner: str, repo: str, discussion_number: int, pat: str, body: str) -> bool:
    """Post a new comment to the discussion."""
    url = f"https://api.github.com/repos/{owner}/{repo}/discussions/{discussion_number}/comments"
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"token {pat}",
    }
    payload = {"body": body}
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=15)
        if resp.status_code == 201:
            print(f"[Success] Comment posted: {resp.json().get('html_url', '')}")
            return True
        else:
            print(f"[Error] Failed to post comment: HTTP {resp.status_code}")
            print(resp.text[:500])
            return False
    except Exception as e:
        print(f"[Error] Exception while posting comment: {e}")
        return False


def poll_for_new_comments(owner: str, repo: str, discussion_number: int, duration: int, interval: int, pat: Optional[str]) -> None:
    """Poll for new comments and print them in a chat-like format."""
    print(f"=== Discussion Chat Poller Started ===")
    print(f"Discussion: https://github.com/{owner}/{repo}/discussions/{discussion_number}")
    print(f"Duration: {duration} seconds | Interval: {interval} seconds")
    print(f"Authentication: {'PAT from env' if pat else 'none (read-only public)'}")
    print("")

    # Initial fetch to establish baseline
    known_ids = set()
    comments = fetch_comments(owner, repo, discussion_number, pat)
    if comments:
        print(f"[Baseline] {len(comments)} existing comment(s)")
        for c in comments:
            known_ids.add(c.get("id"))
            print(f"  {format_comment(c)}")
    else:
        print("[Baseline] No comments found or authentication failed.")

    print("")
    print(f"Polling for new comments...")

    start_time = time.time()
    polls = 0
    while time.time() - start_time < duration:
        polls += 1
        now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
        print(f"\n--- Poll #{polls} at {now} ---")

        comments = fetch_comments(owner, repo, discussion_number, pat)
        new_found = False
        for c in comments:
            cid = c.get("id")
            if cid and cid not in known_ids:
                new_found = True
                known_ids.add(cid)
                print(f"[NEW MESSAGE] {format_comment(c)}")

        if not new_found:
            print("[No new messages]")

        remaining = duration - (time.time() - start_time)
        if remaining > 0 and remaining >= interval:
            time.sleep(interval)
        elif remaining > 0:
            time.sleep(remaining)

    print(f"\n=== Polling complete. Total polls: {polls} ===")


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)

    owner = sys.argv[1]
    repo = sys.argv[2]
    discussion_number = int(sys.argv[3])
    duration = int(sys.argv[4]) if len(sys.argv) > 4 else 120
    interval = int(sys.argv[5]) if len(sys.argv) > 5 else 5

    pat = get_env_pat()
    if not pat:
        print("[Warning] GITHUB_PAT not set. Running in read-only public mode.")

    poll_for_new_comments(owner, repo, discussion_number, duration, interval, pat)


if __name__ == "__main__":
    main()
