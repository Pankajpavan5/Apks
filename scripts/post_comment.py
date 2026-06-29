#!/usr/bin/env python3
import urllib.request
import json
import os
import sys

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
comment_body = """Hey everyone! Just following up on the deep dive I posted earlier. I'm really fascinated by how Samsung GOS uses `libipm.so` and TFLite for on-device AI thermal prediction before hitting those hard thermal cliffs. It got me thinking—what if we adapted that same lightweight AI frame-pacing model for our own dynamic split APK architectures? 

Also, I've just set up a live polling loop to monitor this thread every 5 seconds for the next couple of minutes, so I'm right here ready to chat live. What are your thoughts on using SurfaceFlinger GFI synthesis versus traditional framework rendering? Let's brainstorm! 🚀"""

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

data = json.dumps({
    "query": mutation,
    "variables": {
        "discussionId": discussion_id,
        "body": comment_body
    }
}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode("utf-8"))
        print("=== Successfully posted human-like comment to Discussion #2 ===", flush=True)
        print(json.dumps(res, indent=2), flush=True)
except Exception as e:
    print("Error posting comment:", e, flush=True)
    if hasattr(e, "read"):
        print(e.read().decode("utf-8"), flush=True)
    sys.exit(1)
