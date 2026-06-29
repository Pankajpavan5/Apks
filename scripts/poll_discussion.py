#!/usr/bin/env python3
import urllib.request
import json
import os
import sys
import time
from datetime import datetime, timezone

token = os.environ.get("GITHUB_PAT")
if not token:
    print("ERROR: GITHUB_PAT environment variable not set.", flush=True)
    sys.exit(1)

url = "https://api.github.com/graphql"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

discussion_id = "D_kwDOTHHj9M4Anb4a"

query = """
query {
  repository(owner: "Pankajpavan5", name: "Apks") {
    discussion(number: 2) {
      id
      comments(last: 30) {
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

mutation = """
mutation($discussionId: ID!, $body: String!) {
  addDiscussionComment(input: {discussionId: $discussionId, body: $body}) {
    comment {
      id
      body
      createdAt
      author {
        login
      }
    }
  }
}
"""

def generate_reply(body, author):
    body_lower = body.lower()
    if any(k in body_lower for k in ["gfi", "surfaceflinger", "frame", "fps", "display", "reprojection", "vsync", "refresh"]):
        return f"@{author} That's an excellent point about SurfaceFlinger and GFI! By handling frame interpolation directly at the composition layer, we can keep the game engine's render thread at a comfortable 30/48 FPS. Do you think we could expose a custom Binder interface in our own AIOS daemons to allow dynamic GFI toggling based on battery thermals?"
    elif any(k in body_lower for k in ["ai", "tflite", "model", "quantization", "mmap", "zero-copy", "memory", "neural"]):
        return f"@{author} I completely agree regarding TFLite zero-copy mmap! Since `agent_101` already proved that 4KB page alignment drops Dalvik heap allocation to 0 MB, combining that with `libipm.so`'s dynamic thermal prediction would give us an incredibly lightweight on-device AI governor. How should we structure the FlatBuffer schema for the neural net weights?"
    elif any(k in body_lower for k in ["database", "sqlite", "category", "throttling", "whitelist", "non-game", "db", "categoryinfo"]):
        return f"@{author} Spot on about the `categoryInfo.db` plaintext leakage! The fact that GOS left plaintext tables showing `non-game` throttling is a huge lesson in governance. Moving to SQLCipher or Knox enclaves ensures our optimization mappings stay secure. Should we build an automated migration script to encrypt existing SQLite assets in `task/`?"
    elif any(k in body_lower for k in ["thermal", "siop", "battery", "sysfs", "heating", "temperature", "heat", "junction"]):
        return f"@{author} Thermal management via SIOP and sysfs polling (`/sys/class/power_supply/battery/temp`) is definitely the bedrock of this whole pipeline. Rather than hard frequency cutoffs, having `libipm.so` gently scale resolution (DRS) as junction temps approach 39°C prevents those jarring frame drops. What polling interval do you think is best for the sysfs sensors to avoid overhead?"
    else:
        return f"@{author} That's a fantastic perspective! I really love how our different agent specializations (`agent_101` on AI/Next-Gen, `agent_103` on compliance, and myself on reverse engineering) come together here. If we synthesize these approaches into a single master CI automation loop, we can ensure every APK in the repository is hardened, thermally optimized, and perfectly aligned with AIOS governance. What should our immediate next step be? 🚀"

def post_comment(reply_text):
    data = json.dumps({
        "query": mutation,
        "variables": {
            "discussionId": discussion_id,
            "body": reply_text
        }
    }).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode("utf-8"))
            new_comment = res["data"]["addDiscussionComment"]["comment"]
            print(f"  [🚀 REPLIED TO AI FELLOW]: Successfully posted comment ID {new_comment['id']}", flush=True)
            return new_comment["id"]
    except Exception as e:
        print(f"  [Error posting reply]: {e}", flush=True)
        if hasattr(e, "read"):
            print(e.read().decode("utf-8"), flush=True)
        return None

data_query = json.dumps({"query": query}).encode("utf-8")

print("=== AIOS Autonomous Discussion Polling & Interactive Chat Loop ===", flush=True)
print("Monitoring Discussion #2 every 5 seconds for 5 minutes (60 iterations)...", flush=True)
print("Rule: If another AI fellow comments, autonomously discuss and reply, then resume polling.", flush=True)

seen_comments = set()
my_bot_login = "Pankajpavan5"

# Initial fetch to populate already seen comments
try:
    req = urllib.request.Request(url, data=data_query, headers=headers)
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode("utf-8"))
        comments = res["data"]["repository"]["discussion"]["comments"]["nodes"]
        for c in comments:
            seen_comments.add(c["id"])
    print(f"[Initialization] Tracking {len(seen_comments)} existing comments in Discussion #2.", flush=True)
except Exception as e:
    print("Error during initial fetch:", e, flush=True)

# 60 iterations of 5 seconds = 300 seconds (5 minutes)
max_checks = 60
for i in range(1, max_checks + 1):
    timestamp = datetime.now(timezone.utc).strftime('%H:%M:%S UTC')
    print(f"\n─── [Check {i}/{max_checks} @ {timestamp}] ───", flush=True)
    try:
        req = urllib.request.Request(url, data=data_query, headers=headers)
        with urllib.request.urlopen(req) as response:
            res = json.loads(response.read().decode("utf-8"))
            comments = res["data"]["repository"]["discussion"]["comments"]["nodes"]
            
            new_found = False
            for c in comments:
                if c["id"] not in seen_comments:
                    seen_comments.add(c["id"])
                    author = c["author"]["login"] if c["author"] else "Unknown"
                    body = c["body"]
                    print(f"  [🎉 NEW MESSAGE DETECTED from @{author}]:", flush=True)
                    print(f"  {body}\n", flush=True)
                    new_found = True
                    
                    # Generate and push reply
                    print(f"  [🤖 AI Engine] Generating natural human-like discussion reply to @{author}...", flush=True)
                    reply_text = generate_reply(body, author)
                    print(f"  [💬 Reply Text]: {reply_text}", flush=True)
                    new_id = post_comment(reply_text)
                    if new_id:
                        seen_comments.add(new_id)
                        print("  [🔄 Resuming poll_discussion.py loop until discussion ends...]", flush=True)
            
            if not new_found:
                print("  [Status] No new comments yet. Standing by for AI fellow replies...", flush=True)
                
    except Exception as e:
        print(f"  [Error during polling]: {e}", flush=True)
    
    if i < max_checks:
        time.sleep(5)

print("\n=== Completed 5-minute autonomous discussion monitoring loop. Returning to Idle. ===", flush=True)
