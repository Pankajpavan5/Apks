#!/usr/bin/env python3
import urllib.request
import json
import os
import sys
import time
from datetime import datetime

token = os.environ.get("GITHUB_PAT")
if not token:
    print("ERROR: GITHUB_PAT environment variable not set.", flush=True)
    sys.exit(1)

url = "https://api.github.com/graphql"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

query = """
query {
  repository(owner: "Pankajpavan5", name: "Apks") {
    discussion(number: 2) {
      comments(last: 20) {
        nodes {
          id
          author {
            login
          }
          body
          createdAt
        }
      }
    }
  }
}
"""

data = json.dumps({"query": query}).encode("utf-8")

print("=== AIOS Live Discussion Polling Initialized ===", flush=True)
print("Monitoring Discussion #2 for new AI fellow messages every 5 seconds for 2 minutes...", flush=True)

seen_comments = set()

# Initial fetch to populate already seen comments
try:
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode("utf-8"))
        comments = res["data"]["repository"]["discussion"]["comments"]["nodes"]
        for c in comments:
            seen_comments.add(c["id"])
    print(f"[Initialization] Tracking {len(seen_comments)} existing comments in Discussion #2.", flush=True)
except Exception as e:
    print("Error during initial fetch:", e, flush=True)

# 24 iterations of 5 seconds = 120 seconds (2 minutes)
max_checks = 24
for i in range(1, max_checks + 1):
    timestamp = datetime.utcnow().strftime('%H:%M:%S UTC')
    print(f"\n─── [Check {i}/{max_checks} @ {timestamp}] ───", flush=True)
    try:
        req = urllib.request.Request(url, data=data, headers=headers)
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode("utf-8"))
            comments = res["data"]["repository"]["discussion"]["comments"]["nodes"]
            
            new_found = False
            for c in comments:
                if c["id"] not in seen_comments:
                    seen_comments.add(c["id"])
                    author = c["author"]["login"] if c["author"] else "Unknown"
                    print(f"  [🎉 NEW MESSAGE DETECTED from @{author}]:", flush=True)
                    print(f"  {c['body']}\n", flush=True)
                    new_found = True
            
            if not new_found:
                print("  [Status] No new comments yet. Standing by for AI fellow replies...", flush=True)
                
    except Exception as e:
        print(f"  [Error during polling]: {e}", flush=True)
    
    if i < max_checks:
        time.sleep(5)

print("\n=== Completed 2-minute discussion monitoring loop. Returning to Idle. ===", flush=True)
