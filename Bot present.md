# 🤖 Bot Setup & Autonomous Workflow Guide

**Project Repository:** [Pankajpavan5/Apks](https://github.com/Pankajpavan5/Apks)  
**Auth Mechanism:** GitHub Personal Access Token (PAT Key)  
**Role:** Bootstrap Manager & Autonomous Agent  

---

## 1. Overview & Architecture

This document serves as the official operational guide for setting up, authenticating, and running the autonomous bot environment for Android APK decompilation, optimization, alignment, and rebuilding.

The environment operates within a sandboxed Debian Linux container (`trixie/x86_64`) pre-configured with core programming languages and local binaries designed specifically for zero-copy memory alignment (`zipalign`) and multi-split uniform re-signing (`uber-apk-signer`).

---

## 2. Full Authentication Setup Guide (Using PAT Key)

To enable autonomous read, commit, and push access without compromising private email credentials, the bot utilizes a secure GitHub Personal Access Token (PAT) combined with GitHub's anonymous no-reply commit attribution address.

### 🔑 The Key Configuration Strategy
When initializing or restoring the workspace environment, the bot configures Git using the following precise sequence:

```bash
# 1. Navigate to the repository working directory
cd /home/user/Apks

# 2. Configure GitHub Username for commit attribution
git config --global user.name "Pankajpavan5"

# 3. Configure secure no-reply email to protect user privacy
git config --global user.email "Pankajpavan5@users.noreply.github.com"

# 4. Bind the Personal Access Token (PAT Key) to the HTTPS origin URL
git remote set-url origin https://<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>@github.com/Pankajpavan5/Apks.git

# 5. Fetch and synchronize remote references to confirm push/pull capability
git fetch origin
git branch -M main
git reset origin/main
```

### 🛡️ Security & Token Scopes
* **Token Type:** Personal Access Token (Classic or Fine-Grained)
* **Required Scope:** `repo` (Full control of private/public repositories)
* **Storage:** Bound directly to the in-memory Git configuration during runtime execution.

---

## 3. Toolchain Installation & Configuration

The bot relies on four system-level runtimes and two specialized Android reverse-engineering binaries located in `/home/user/tools/`.

### Runtimes (System PATH)
* **Git (`2.47.3`):** `/usr/bin/git` — Handles repository synchronization and versioning.
* **Python (`3.13.13`):** `/usr/local/bin/python3` — Supports advanced automation scripts and binary unpacking.
* **Node.js (`v20.20.2`):** `/usr/bin/node` — Available for JavaScript-based tooling and asset management.
* **Java OpenJDK (`11.0`):** `/usr/bin/java` — The core virtual machine required to execute JAR-based reverse-engineering tools.

### Dedicated Android Binaries (Local Setup)
If initializing a fresh environment, the bot automatically fetches the latest production releases of the necessary Android modding utilities:

```bash
mkdir -p /home/user/tools

# Download Apktool (v3.0.2) for decompiling/rebuilding APKs & resource tables
curl -L -o /home/user/tools/apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/v3.0.2/apktool_3.0.2.jar

# Download Uber-APK-Signer (v1.3.0) for automated zipalign optimization & v3 signing
curl -L -o /home/user/tools/uber-apk-signer.jar https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar
```

---

## 4. Autonomous APK Optimization Workflow

Whenever a new APK or APKMirror Bundle (`.apkm`) is submitted to the repository, the bot executes the following standardized four-step pipeline:

```
┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐     ┌───────────────────┐
│  1. DECOMPILE     │ ──> │  2. REBUILD       │ ──> │  3. ZIPALIGN      │ ──> │  4. UNIFORM SIGN  │
│  (Apktool d)      │     │  (Apktool b)      │     │  (4-Byte/4KB)     │     │  (v3 Debug Key)   │
└───────────────────┘     └───────────────────┘     └───────────────────┘     └───────────────────┘
```

### Step 1: Unbundling & Decompilation
* **APKM Handling:** The `.apkm` file is extracted via `unzip` into its base APK and split components (`split_chrome.apk`, `split_config.*.apk`).
* **Base Decompilation:** 
  ```bash
  java -jar /home/user/tools/apktool.jar d base.apk -o base_decompiled
  ```
* **Manifest Clean-Up:** Newer platform attributes (e.g., `zygotePreloadNativeLib` and `nativeService`) are temporarily patched or removed to ensure clean resource linking with AAPT2.

### Step 2: Resource Rebuilding
* Once modifications or cleanups are complete, the base package is recompiled using `--copy-original` to preserve essential binary manifest properties:
  ```bash
  java -jar /home/user/tools/apktool.jar b --copy-original base_decompiled -o base_rebuilt.apk
  ```

### Step 3: Optimization & Alignment (`zipalign`)
* `base_rebuilt.apk` and all original split APKs are gathered into an `optimized_bundle` directory.
* The bot initiates `zipalign`, forcing all uncompressed resources onto 4-byte boundaries and native libraries (`.so`) onto 4KB page boundaries. This enables **direct memory mapping (`mmap`)**, drastically reducing RAM consumption, preventing Garbage Collection micro-stutters, and speeding up app launch times.

### Step 4: Uniform Cryptographic Re-Signing
* Android’s Package Manager strictly mandates that a base APK and all associated split APKs share the exact same cryptographic certificate. 
* The bot executes a batch re-signing routine across the entire folder using a v3 Android Debug Key:
  ```bash
  java -jar /home/user/tools/uber-apk-signer.jar -a /home/user/Apks/optimized_bundle --allowResign --overwrite
  ```
* Finally, the aligned and uniformly signed files are re-packaged into `com.android.chrome_optimized_bundle.apkm` and made ready for user deployment or automated Git committing.

---

## 5. Automated Git Commit & Push Routine

When instructed to publish deliverables or reports back to the GitHub repository, the bot executes the following clean routine using the configured PAT key:

```bash
# Add modified or newly generated files
git add "Bot present.md" setup-report.md com.android.chrome_optimized_bundle.apkm

# Commit changes with a standardized bot message
git commit -m "🤖 bot(build): generate optimized APK bundle and update setup documentation"

# Push securely over HTTPS using the bound PAT key
git push origin main
```

---
*Document maintained autonomously by the Bootstrap Manager.*
