# BuildMaster-Shizuku AIOS Deployment Guide

**Status:** PRODUCTION READY  
**Version:** 1.0  
**Generated:** 2026-07-02  
**Agent:** BuildMaster-Shizuku (Gradle/APK Optimization Engine)  
**Target System:** Debian 13 x86_64, 2-core Xeon @ 2.6GHz, 2GB RAM  

---

## 📋 Quick Index

| Document | Purpose | Status |
|----------|---------|--------|
| **AIOS_AGENT_BUILD_GUIDE.md** | Comprehensive 15-section build guide with all details | ✓ Complete |
| **AGENT_SPEC_BuildMaster_Shizuku.yml** | Formal agent specification (AIOS format) | ✓ Complete |
| **SAMPLE_TASK_BUILD_SHIZUKU.yml** | Example task workflow (copy to tasks/pending/) | ✓ Complete |
| **agent_workflow.sh** | Executable workflow script (deploy to agents/) | ✓ Ready |
| **README_DEPLOYMENT.md** | This file — deployment checklist | ✓ You are here |

---

## 🚀 DEPLOYMENT CHECKLIST

### Phase 1: System Validation (5 min)

- [ ] **OS & Hardware**
  - [ ] Verify Debian 13: `cat /etc/os-release`
  - [ ] Verify 2-core CPU: `nproc` (should output 2)
  - [ ] Verify 2GB RAM: `free -h` (Mem: ~1.9–2.0 Gi)
  - [ ] Verify disk space: `df -h /` (available >15GB)

- [ ] **Java 21**
  ```bash
  java -version
  # Expected: "openjdk version \"21.x.x\""
  ```

- [ ] **Android SDK & NDK**
  ```bash
  ls -la /android/sdk/platforms/android-36/
  ls -la /android/ndk/29.0.13113456/
  # Both should exist and be readable
  ```

- [ ] **Git**
  ```bash
  git --version
  # Expected: git version 2.40+
  git config user.name "BuildMaster-Shizuku"
  git config user.email "agent@aios.local"
  ```

### Phase 2: Repository Setup (10 min)

- [ ] **Clone AIOS repo** (or initialize new one)
  ```bash
  cd /workspace
  git clone https://github.com/Pankajpavan5/Apks.git AIOS_root
  cd AIOS_root
  ```

- [ ] **Extract Shizuku source**
  ```bash
  cd /workspace
  unzip Shizuku-13_6_0.zip
  cd Shizuku-13.6.0
  ```

- [ ] **Initialize agent directory structure**
  ```bash
  mkdir -p agents/BuildMaster-Shizuku/{agent_info,memory,storage}
  mkdir -p tasks/{pending,complete,assign}
  mkdir -p message_system/{inbox,outbox}
  mkdir -p ai_brain
  ```

- [ ] **Copy agent specification files**
  ```bash
  cp AGENT_SPEC_BuildMaster_Shizuku.yml agents/BuildMaster-Shizuku/agent_info/spec.yml
  cp AIOS_AGENT_BUILD_GUIDE.md agents/BuildMaster-Shizuku/agent_info/BUILD_GUIDE.md
  ```

- [ ] **Copy task template**
  ```bash
  cp SAMPLE_TASK_BUILD_SHIZUKU.yml tasks/pending/BUILD_SHIZUKU_RELEASE.yml
  ```

- [ ] **Deploy workflow script**
  ```bash
  cp agent_workflow.sh agents/BuildMaster-Shizuku/
  chmod +x agents/BuildMaster-Shizuku/agent_workflow.sh
  ```

### Phase 3: Agent Initialization (15 min)

- [ ] **Create initial memory files**
  ```bash
  cat > agents/BuildMaster-Shizuku/memory/build_baseline.md << 'EOF'
  # BuildMaster-Shizuku Build Baseline
  
  ## Initial System Profile
  - Date: $(date -u +%Y-%m-%d)
  - System: Debian 13, 2-core Xeon, 2GB RAM
  - Java: 21
  - Gradle: 8.6+
  - Android SDK: 36
  - NDK: 29.0.13113456
  
  ## Optimization Profile
  - Gradle JVM: -Xmx1200m (G1GC)
  - Workers: 2 (2-core lockdown)
  - Parallel: true
  - Cache: enabled
  
  ## Performance Baseline (To Be Established)
  (Populated after first successful build)
  
  EOF
  ```

- [ ] **Create AI brain problem log**
  ```bash
  cat > ai_brain/Problem.md << 'EOF'
  # BuildMaster-Shizuku: Known Issues & Solutions
  
  ## Issue #1: Gradle Daemon Heap Exhaustion [RESOLVED]
  **Symptom:** Build stalls, OutOfMemoryError
  **Solution:** Set org.gradle.jvmargs=-Xmx1200m in gradle.properties
  **Status:** Deployed
  
  ## Issue #2: CMake Single-Threaded Compilation [ACKNOWLEDGED]
  **Symptom:** CMake reports parallel level: 1
  **Cause:** NDK 29 design constraint
  **Workaround:** No practical fix; accepted behavior
  **Status:** Monitoring
  
  (Add findings after build runs)
  
  EOF
  ```

- [ ] **Validate agent files**
  ```bash
  ls -la agents/BuildMaster-Shizuku/
  # Should show: agent_info/, memory/, storage/, agent_workflow.sh
  
  ls -la agents/BuildMaster-Shizuku/memory/
  # Should show: build_baseline.md
  
  cat ai_brain/Problem.md
  # Should display issue log
  ```

### Phase 4: Gradle & Build System Tuning (5 min)

- [ ] **Apply optimized gradle.properties**
  ```bash
  cd /workspace/Shizuku-13.6.0
  
  # Backup original
  cp gradle.properties gradle.properties.original
  
  # Deploy optimized version (from agent_workflow.sh step 3)
  cat > gradle.properties << 'EOF'
  org.gradle.jvmargs=-Xmx1200m -Xms512m -XX:+UseG1GC -XX:G1HeapRegionSize=8m -XX:+ParallelRefProcEnabled
  org.gradle.workers.max=2
  org.gradle.parallel=true
  org.gradle.configureondemand=true
  org.gradle.caching=true
  org.gradle.build.cache.local.enabled=true
  android.enableProfileInstaller=false
  android.enableVcsInfo=false
  kotlin.daemon.jvm.options=-Xmx800m
  EOF
  ```

- [ ] **Verify gradle loads settings**
  ```bash
  ./gradlew properties | grep "org.gradle.jvmargs" | head -1
  # Expected: org.gradle.jvmargs=-Xmx1200m ...
  
  ./gradlew properties | grep "org.gradle.workers.max"
  # Expected: org.gradle.workers.max=2
  ```

### Phase 5: Test Build (15 min)

- [ ] **Run debug build (quick validation)**
  ```bash
  cd /workspace/Shizuku-13.6.0
  
  time ./gradlew :manager:assembleDebug
  # Expected: <120 seconds, ~12 MB APK
  # Output: manager/build/outputs/apk/debug/shizuku-*-debug.apk
  ```

- [ ] **Verify APK was created**
  ```bash
  ls -lh manager/build/outputs/apk/debug/shizuku-*.apk
  # Should show ~12 MB file
  
  aapt dump badging manager/build/outputs/apk/debug/shizuku-*.apk | head -5
  # Should show package, versionCode, versionName, targetSdkVersion
  ```

- [ ] **Test release build (full optimization)**
  ```bash
  cd /workspace/Shizuku-13.6.0
  
  time ./gradlew :manager:assembleRelease --profile
  # Expected: 180–240 seconds, ~4 MB APK
  # Output: out/apk/shizuku-v13.6.0.rN.HASH-release.apk
  #         out/mapping/mapping-13.6.0.rN.HASH.txt
  ```

- [ ] **Verify release APK & artifacts**
  ```bash
  ls -lh out/apk/shizuku-*-release.apk
  # Should show ~4.1 MB file
  
  ls -lh out/mapping/mapping-*.txt
  # Should show ProGuard mapping file
  
  aapt dump badging out/apk/shizuku-*-release.apk | head -5
  jarsigner -verify out/apk/shizuku-*-release.apk 2>&1 | head -3
  # Both should succeed
  ```

### Phase 6: Agent Workflow Test (10 min)

- [ ] **Execute full agent workflow**
  ```bash
  cd /workspace/Shizuku-13.6.0
  bash agents/BuildMaster-Shizuku/agent_workflow.sh release
  
  # Expected output:
  # ✓ Environment validated
  # ✓ System audit generated
  # ✓ gradle.properties deployed
  # ✓ Build completed in ~185s
  # ✓ APK validation complete
  # ✓ Report generated
  # ✓ Memory updated
  # ✓ Git committed
  ```

- [ ] **Verify workflow artifacts**
  ```bash
  ls -la build_report_*.md
  # Should show recent report
  
  git log --oneline -3
  # Should show build(Shizuku) commit
  
  git tag | grep v13.6.0-build
  # Should show recent tag
  ```

- [ ] **Check memory updates**
  ```bash
  cat agents/BuildMaster-Shizuku/memory/build_baseline.md | tail -20
  # Should show build run logged
  
  cat agents/BuildMaster-Shizuku/memory/performance_log.csv
  # Should show CSV entry with metrics
  ```

### Phase 7: Inter-Agent Communication Setup (5 min)

- [ ] **Create message system templates**
  ```bash
  mkdir -p message_system/System/{Script,Rules,CommonInstruction,Shortcut,Template}
  
  # Example: Create build success notification template
  cat > message_system/Template/BUILD_SUCCESS.txt << 'EOF'
  FROM: BuildMaster-Shizuku
  TO: <AGENT_NAME>
  TIMESTAMP: <TIMESTAMP>
  STATUS: SUCCESS
  
  Build completed successfully.
  
  Artifact: <APK_PATH>
  Size: <SIZE>
  Duration: <DURATION>s
  
  Next Steps: <ACTIONS>
  EOF
  ```

- [ ] **Define inter-agent routing rules**
  ```bash
  cat > message_system/System/Rules/BUILD_COMPLETION_ROUTING.txt << 'EOF'
  Rule: On release build success
  Route to: TestRunner-APK
  Template: BUILD_SUCCESS.txt
  Urgency: NORMAL
  
  Rule: On build failure (OOM)
  Route to: Ops, CodeOptimizer-Shizuku
  Template: BUILD_FAILURE_OOM.txt
  Urgency: HIGH
  EOF
  ```

### Phase 8: Git Synchronization (5 min)

- [ ] **Configure Git remote**
  ```bash
  cd /workspace/Shizuku-13.6.0
  git remote -v
  # Expected: origin = https://github.com/Pankajpavan5/Apks.git
  
  # If not set:
  git remote add origin https://github.com/Pankajpavan5/Apks.git
  ```

- [ ] **Test Git push (non-blocking)**
  ```bash
  git push origin main
  # If fails due to permissions, that's OK for now
  
  git push origin --tags
  # Tags can be pushed separately
  ```

- [ ] **Verify GitHub integration**
  ```bash
  # Check GitHub Actions (if configured)
  # Verify branch protection rules
  # Ensure secrets (if needed for signing) are set
  ```

### Phase 9: Monitoring & Automation (Optional)

- [ ] **Set up build metrics collection**
  ```bash
  cat > agents/BuildMaster-Shizuku/storage/metrics.csv << 'EOF'
  timestamp,duration_sec,apk_size_mb,status,variant
  EOF
  ```

- [ ] **Configure optional CI/CD trigger** (if using GitHub Actions)
  ```bash
  mkdir -p .github/workflows
  # Create github-actions.yml for daily scheduled builds
  ```

- [ ] **Set up log rotation** (for long-term operation)
  ```bash
  # Ensure /tmp/build_*.log files are cleaned weekly
  # Or move to agents/BuildMaster-Shizuku/storage/logs/
  ```

---

## ✅ VALIDATION CHECKLIST (Post-Deployment)

After completing all phases, verify:

- [ ] **Agent Directory Structure**
  ```
  agents/BuildMaster-Shizuku/
  ├── agent_info/
  │   ├── spec.yml
  │   ├── BUILD_GUIDE.md
  │   └── system_baseline.md
  ├── memory/
  │   ├── build_baseline.md
  │   └── performance_log.csv
  ├── storage/
  │   └── (empty, for build artifacts)
  └── agent_workflow.sh
  ```

- [ ] **Build System**
  ```bash
  ./gradlew --version          # Returns Gradle 8.6+
  java -version               # Returns Java 21
  aapt dump badging --help     # AAPT2 available
  ```

- [ ] **AIOS Integration**
  ```bash
  git log --oneline -1         # Latest commit is build(Shizuku): ...
  ls tasks/pending/ | grep -i build  # Tasks in queue
  ls message_system/           # Message folders exist
  ```

- [ ] **Agent Learning System**
  ```bash
  cat ai_brain/Problem.md      # Issue log exists
  cat agents/BuildMaster-Shizuku/memory/build_baseline.md | tail -5
  # Shows recent build run
  ```

- [ ] **Test Workflow (Full Cycle)**
  ```bash
  bash agents/BuildMaster-Shizuku/agent_workflow.sh release
  # Completes without errors in <250s
  # Produces build_report_*.md
  # Commits to git
  ```

---

## 🎯 SUCCESS CRITERIA

Agent is **READY FOR PRODUCTION** when:

✓ All deployment phases complete  
✓ Test debug build succeeds (<120s)  
✓ Test release build succeeds (<240s)  
✓ Full agent_workflow.sh completes without errors  
✓ Git artifacts pushed to origin  
✓ Memory system populated with baseline metrics  
✓ Inter-agent communication paths validated  
✓ No unresolved issues in ai_brain/Problem.md  

---

## 📊 EXPECTED PERFORMANCE BASELINES

After first build:

| Metric | Expected | Range |
|--------|----------|-------|
| **Debug Build Time** | 90s | 60–120s |
| **Release Build Time** | 185s | 180–240s |
| **APK Size (Release)** | 4.1 MB | 3.9–4.2 MB |
| **Heap Peak** | 1.18 GB | 1.0–1.3 GB |
| **Gradle Daemon Reuse** | ~70% cache hit | >60% |
| **Build Success Rate** | 100% | >99% |

---

## 🔧 TROUBLESHOOTING (Common Issues)

### Issue: "gradlew: command not found"
**Solution:** Ensure you're in `/workspace/Shizuku-13.6.0/` directory
```bash
cd /workspace/Shizuku-13.6.0
ls -la gradlew  # Should exist
chmod +x gradlew
```

### Issue: "ANDROID_SDK_ROOT not set"
**Solution:** Set environment variable
```bash
export ANDROID_SDK_ROOT=/android/sdk
# Verify: ls $ANDROID_SDK_ROOT/platforms/android-36/
```

### Issue: "Java version is not 21"
**Solution:** Update $JAVA_HOME
```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
java -version  # Should show 21.x.x
```

### Issue: "Build hangs or OOM after 5+ min"
**Solution:** Gradle daemon memory issue
```bash
./gradlew --stop
# Verify gradle.properties has: org.gradle.jvmargs=-Xmx1200m -XX:+UseG1GC
./gradlew clean :manager:assembleRelease  # Retry
```

### Issue: "APK not found in out/apk/"
**Solution:** Check build logs for errors
```bash
tail -100 /tmp/build_*.log | grep -i "error\|fail"
# Common causes: Kotlin compilation error, missing dependency
```

### Issue: "Git push fails (network down)"
**Solution:** Non-blocking; will retry on next cycle
```bash
git status  # Shows commits staged
git push origin main  # Try again when network returns
```

---

## 📝 DOCUMENTATION REFERENCES

For detailed information, consult:

1. **Build Guide:** `AIOS_AGENT_BUILD_GUIDE.md` (15 sections)
   - Comprehensive workflow, optimization details, troubleshooting
   - **Read if:** You need deep technical understanding

2. **Agent Specification:** `AGENT_SPEC_BuildMaster_Shizuku.yml`
   - Formal agent definition, capabilities, constraints
   - **Read if:** You're integrating with other AIOS agents

3. **Task Definition:** `SAMPLE_TASK_BUILD_SHIZUKU.yml`
   - Task workflow, success criteria, inter-agent communication
   - **Read if:** You're defining custom build tasks

4. **Workflow Script:** `agent_workflow.sh`
   - Executable build automation, step-by-step execution
   - **Run if:** You want to execute a full build cycle

---

## 🚀 NEXT STEPS

1. **Immediate (Today)**
   - [ ] Complete phases 1–5 (validation + test builds)
   - [ ] Run full agent_workflow.sh at least once
   - [ ] Verify git commits appear in origin/main

2. **This Week**
   - [ ] Set up inter-agent communication with TestRunner-APK
   - [ ] Populate performance baseline metrics
   - [ ] Create GitHub Issues for any identified optimizations

3. **This Month**
   - [ ] Run weekly review cycle (analyze metrics, adjust tuning)
   - [ ] Integrate with AIOS task scheduler (GitHub Actions or cron)
   - [ ] Plan optimization iterations (e.g., ProGuard rule tuning)

4. **Future**
   - [ ] Extend to other projects (NexusCompress APK, etc.)
   - [ ] Implement APK variant automation (API-level specific)
   - [ ] Add advanced profiling (CMake parallelism, D8 optimization)

---

## 📞 SUPPORT & ESCALATION

| Issue | Escalate To | Contact |
|-------|-------------|---------|
| Build source errors | CodeOptimizer-Shizuku | GitHub Issues |
| APK fails on device | TestRunner-APK | Message system |
| Gradle/SDK problems | Ops (System Admin) | Direct escalation |
| Reproducibility loss | ArchiveManager | Memory system log |
| ProGuard rule bugs | AndroidOptimizer | Issue database |

---

**Generated:** 2026-07-02 08:00:00 UTC  
**Version:** 1.0  
**Status:** READY FOR DEPLOYMENT  

Questions? Refer to `AIOS_AGENT_BUILD_GUIDE.md` or escalate to appropriate AIOS agent.
