# PAT Vault Decryption Guide

## Overview

This repository stores GitHub Personal Access Tokens (PATs) in an encrypted format using **AES-256-GCM**. The encrypted record is stored in `encrypted_pat.md` at the repository root.

This guide explains how to decrypt the PAT, verify the format, and use it securely in Python scripts.

---

## Encrypted Record Format

The encrypted record is a JSON object with these fields:

```json
{
  "key_id": "key_20260628104501_7d6219df",
  "cipher_suite": "AES-256-GCM",
  "nonce_b64": "RvV/eRaZAfMbqNCO",
  "ciphertext_tag_b64": "J/EFDkcwx0tSCLb8FrzifWYJCV8sae8IKAl/KXOWVizjVwbaaQ96rvlvaKi4SkeV+u57xjIhlq8=",
  "created_at": "2026-06-28T10:45:01.817375+00:00",
  "rotated_at": null
}
```

| Field | Meaning |
|-------|---------|
| `key_id` | Unique identifier for the encryption key used |
| `cipher_suite` | Encryption algorithm (`AES-256-GCM`) |
| `nonce_b64` | Base64-encoded nonce (IV) used for encryption |
| `ciphertext_tag_b64` | Base64-encoded ciphertext **plus** 16-byte GCM authentication tag |
| `created_at` | ISO 8601 timestamp when the record was created |
| `rotated_at` | ISO 8601 timestamp of last key rotation, or `null` |

### Ciphertext + Tag Layout

AES-GCM produces a 16-byte authentication tag appended to the ciphertext. After base64-decoding `ciphertext_tag_b64`:

```
+----------------------------+------------------+
|        ciphertext          |   tag (16 bytes) |
+----------------------------+------------------+
```

---

## Prerequisites

Install the Python `cryptography` library if you are not using the project vault wrapper:

```bash
pip install cryptography
```

> If you are using the bundled `pat_vault` package, it already manages the key and decryption for you.

---

## Manual Decryption (Python)

Use this approach only when you need to inspect or understand the raw decryption process.

```python
import base64
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# Load the encrypted record from the repository
record = {
    "key_id": "key_20260628104501_7d6219df",
    "cipher_suite": "AES-256-GCM",
    "nonce_b64": "RvV/eRaZAfMbqNCO",
    "ciphertext_tag_b64": "J/EFDkcwx0tSCLb8FrzifWYJCV8sae8IKAl/KXOWVizjVwbaaQ96rvlvaKi4SkeV+u57xjIhlq8=",
    "created_at": "2026-06-28T10:45:01.817375+00:00",
    "rotated_at": null
}

# Provide your 32-byte AES-256 key. In production, load this from a secure
# key manager, environment variable, or password vault — never hardcode it.
KEY_B64 = "YOUR_BASE64_ENCODED_32_BYTE_KEY"
key = base64.b64decode(KEY_B64)

assert len(key) == 32, "AES-256 requires a 32-byte key"

# Decode the nonce and ciphertext+tag
nonce = base64.b64decode(record["nonce_b64"])
ciphertext_tag = base64.b64decode(record["ciphertext_tag_b64"])

# Split ciphertext and authentication tag
tag = ciphertext_tag[-16:]
ciphertext = ciphertext_tag[:-16]

# Decrypt and authenticate
aesgcm = AESGCM(key)
plaintext = aesgcm.decrypt(nonce, ciphertext + tag, associated_data=None)

pat = plaintext.decode("utf-8")

# Only print a prefix; never expose the full PAT in logs
print(f"Decrypted PAT prefix: {pat[:8]}...")
```

### Required outputs

- If the key and ciphertext are correct, `plaintext` will contain the UTF-8 encoded PAT.
- If the key is wrong or the data is tampered with, `AESGCM.decrypt()` raises `cryptography.exceptions.InvalidTag`.

---

## Using the `GitHubPATVault` Class (Recommended)

The recommended way to consume the vault is through the provided wrapper. It keeps the plaintext PAT in RAM only inside the context manager and automatically builds the `Authorization` header.

```python
from pat_vault.src.github_pat_vault import GitHubPATVault
import requests

# Path to the vault records file
vault = GitHubPATVault("/home/user/.pat_vault/records.json")

# Plaintext exists in RAM only inside this block
with vault.get_github_auth_header("user_github_pat") as headers:
    response = requests.get("https://api.github.com/user", headers=headers)

print("Authenticated Request Status:", response.status_code)
```

### How it works

1. The vault reads all encrypted records from the JSON file.
2. It locates the record matching the requested key alias (`user_github_pat`).
3. It decrypts the ciphertext using the configured master key.
4. It returns a `headers` dict containing `Authorization: token <PAT>`.
5. When the `with` block exits, the plaintext PAT is dropped from scope.

---

## Security Best Practices

1. **Never store plaintext PATs in the repository.** Only the encrypted ciphertext and metadata should be committed.
2. **Keep the encryption key separate.** Store the key in a password manager, KMS, or environment variable; never commit it alongside the ciphertext.
3. **Minimize plaintext lifetime.** Use context managers or `with` blocks so the decrypted PAT is available in RAM only when needed.
4. **Do not log the PAT.** If you must print a value, print only a short prefix (e.g., `ghp_xxx...`) or a hash.
5. **Rotate keys regularly.** When rotating, update the `rotated_at` field and generate a new ciphertext.
6. **Use HTTPS only.** Always send PATs over TLS-encrypted channels.
7. **Use least-privilege tokens.** Ensure the GitHub PAT has only the scopes required for its task.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `InvalidTag` exception | Wrong key, corrupted ciphertext, or mismatched nonce | Verify the key and record contents |
| `ValueError: Invalid key size` | Key is not 32 bytes | Decode the base64 key and check its length |
| `binascii.Error` | Malformed base64 string | Ensure `nonce_b64` and `ciphertext_tag_b64` are copied exactly |
| `KeyError: user_github_pat` | Alias not found in vault records | Check the key alias in `records.json` |

---

## File Locations

| File | Purpose |
|------|---------|
| `encrypted_pat.md` | Encrypted PAT vault record + usage snippet |
| `pat_vault/src/github_pat_vault.py` | Vault implementation (if available) |
| `docs/decryption_guide.md` | This guide |
