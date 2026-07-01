#!/usr/bin/env bash
# AIOS /anylasis runner for agent_101 ANALYSER.
# Reads memory, reports, tasks, instructions, scripts, docs, and research;
# extracts problem/solution evidence; writes memory/problem&solution.md.
set -euo pipefail

REPO_ROOT="${1:-/home/user/Apks}"
OUT_FILE="$REPO_ROOT/memory/problem&solution.md"
TMP_DIR="${TMPDIR:-/tmp}/aios_anylasis_$$"
mkdir -p "$TMP_DIR"

cd "$REPO_ROOT"

python3 - <<'PY'
from pathlib import Path
from datetime import datetime, timezone
import re
from collections import defaultdict, Counter

repo = Path('/home/user/Apks')
out = repo / 'memory' / 'problem&solution.md'
scan_roots = ['memory', 'reports', 'task', 'instructions', 'scripts', 'docs', 'research', 'Agents', 'message']
patterns = {
    'build_failed': r'BUILD FAILED|FAILURE: Build failed|Execution failed for task',
    'build_success': r'BUILD SUCCESSFUL',
    'exception': r'Traceback|Exception|NoSuchMethodError|UnsupportedClassVersionError|OverflowError|ValueError',
    'permission': r'Permission denied|Could not open lock file|Unable to acquire.*lock',
    'missing_file': r'No such file|not found|No such remote|does not appear to be a git repository',
    'timeout': r'timeout|No output|unresponsive',
    'oom': r'OOM|Out of memory|Killed process|daemon disappeared|Gradle build daemon disappeared',
    'android_sdk': r'ANDROID_HOME|sdkmanager|source\.properties|NDK|android\.jar|build-tools|cmdline-tools',
    'dependency': r'Could not resolve|handshake_failure|Maven|dependency|Gradle wrapper',
    'kotlin_compose': r'Unresolved reference|Compose|material-icons|HorizontalDivider|KeyframesSpec|Byte.*Int|rememberCoroutineScope|withContext|launch',
    'apktool': r'apktool|uber-apk-signer|zipalign|apksigner|APKTool',
    'security': r'PAT|token|secret|ghp_|credential|Push Protection',
    'compression': r'round-trip|SHA256|BPE|LZ77|BWT|ARLE|Range coder|Huffman|LZMA|7z|ZIP|compression|decompress',
    'zarchiver': r'ZArchiver|ContentProvider|get=accounts|openFile|w2|w4|DocumentsUI|AppsFilter|queries',
}
compiled = {k: re.compile(v, re.I) for k, v in patterns.items()}

files = []
for root in scan_roots:
    p = repo / root
    if not p.exists():
        continue
    for f in p.rglob('*'):
        if f.is_file() and f.stat().st_size < 6_000_000:
            files.append(f)

hits = defaultdict(list)
for f in sorted(files):
    try:
        text = f.read_text(errors='ignore')
    except Exception:
        continue
    for i, line in enumerate(text.splitlines(), 1):
        s = line.strip()
        if not s:
            continue
        for key, rx in compiled.items():
            if rx.search(s):
                hits[key].append((str(f.relative_to(repo)), i, s[:260]))

# Curated canonical database from current AIOS memory/reports and learned HTML chats.
# The grep evidence section below backs this with file references.
canonical = [
    {
        'id': 'git-origin-missing', 'severity': 'high', 'category': 'git', 'status': 'solved/workaround',
        'problem': "Git remote origin missing or unauthenticated across workspace resets.",
        'symptom': "fatal: 'origin' does not appear to be a git repository; fatal: No such remote 'origin'; could not read Username for https://github.com.",
        'root': ".git/config can be excluded from snapshots, reset, or intentionally kept token-free.",
        'solution': "Re-add/set clean origin each session. Use token only transiently for fetch/push, not persisted in .git/config.",
        'verify': "git remote -v; git fetch origin main; git status --short --branch",
        'prevent': "Startup protocol must validate origin before any push/pull.",
    },
    {
        'id': 'html-encoded-bash', 'severity': 'medium', 'category': 'bash', 'status': 'solved',
        'problem': "Connection commands copied from HTML contain encoded ampersands.",
        'symptom': "&amp;&amp; or nested &amp;amp;&amp;amp; causes bash syntax errors near '&'.",
        'root': "Web UI encodes '&' repeatedly in saved/copied commands.",
        'solution': "Decode HTML entities before execution until logical operators become real &&.",
        'verify': "printf '%s' command | python3 -c 'import html,sys; print(html.unescape(sys.stdin.read()))'",
        'prevent': "Never execute raw HTML-encoded connection strings.",
    },
    {
        'id': 'android-sdk-offline', 'severity': 'critical', 'category': 'android-build', 'status': 'open unless offline SDK exists',
        'problem': "Normal Android Gradle source build cannot run without Android SDK/build-tools/platform files.",
        'symptom': "ANDROID_HOME empty, sdkmanager missing/broken, android.jar/aapt2/d8 unavailable.",
        'root': "AGP requires SDK components; user may forbid Android SDK download.",
        'solution': "If SDK download forbidden: use APKTool rebuild/sign pipeline from existing APK, or provide complete offline SDK + Maven/Gradle cache bundle.",
        'verify': "test -f $ANDROID_HOME/platforms/android-XX/android.jar && test -x $ANDROID_HOME/build-tools/XX/aapt2",
        'prevent': "Choose build path first: APKTool path for no-SDK, Gradle path only with complete SDK/cache.",
    },
    {
        'id': 'gradle-low-memory-oom', 'severity': 'critical', 'category': 'gradle', 'status': 'solved/workaround',
        'problem': "Gradle/Kotlin/dex builds die on 2GB RAM systems.",
        'symptom': "Gradle build daemon disappeared; Out of memory: Killed process java; No output/timeouts.",
        'root': "Heap too high, no swap, too many workers, large Compose/dex workload.",
        'solution': "Use Xmx1024m, SerialGC, daemon=false, parallel=false, kotlin daemon Xmx768m, workers=1; kill stale java; add swap when allowed.",
        'verify': "dmesg | grep -i 'oom\\|kill'; ./gradlew assembleDebug --no-daemon --max-workers=1 > build.log 2>&1",
        'prevent': "All Android builds on this VM must use low-memory Gradle profile before first build.",
    },
    {
        'id': 'tail-hides-errors', 'severity': 'medium', 'category': 'bash', 'status': 'solved',
        'problem': "Piping long builds directly to tail hides root causes.",
        'symptom': "Only last 40-100 lines visible; earlier dependency/compiler errors lost.",
        'root': "tail truncates context before diagnosis.",
        'solution': "Always write full log, capture exit code, then tail: cmd > build.log 2>&1; ec=$?; tail -100 build.log; exit $ec.",
        'verify': "test -s build.log && grep -nE 'FAILED|Exception|error' build.log | head",
        'prevent': "No direct `cmd | tail` for final verification commands.",
    },
    {
        'id': 'gradlew-not-executable', 'severity': 'medium', 'category': 'gradle', 'status': 'solved',
        'problem': "Gradle wrapper not executable after unzip/git checkout.",
        'symptom': "./gradlew: Permission denied.",
        'root': "Executable bit lost or not set.",
        'solution': "chmod +x gradlew and commit executable mode if required.",
        'verify': "test -x gradlew && ./gradlew --version",
        'prevent': "Check wrapper executable bit before build.",
    },
    {
        'id': 'java-home-invalid-or-old', 'severity': 'high', 'category': 'java', 'status': 'solved/workaround',
        'problem': "JAVA_HOME invalid or Java version too old for SDK/AGP.",
        'symptom': "JAVA_HOME invalid directory; UnsupportedClassVersionError class file version 61; TLS handshake_failure under old Java.",
        'root': "Workspace package state can reset; sdkmanager/AGP require Java 17+; Java 11 may fail TLS/dependency resolution.",
        'solution': "Verify JDK path before every build; use Java 21 when available.",
        'verify': "test -x $JAVA_HOME/bin/java && $JAVA_HOME/bin/java -version",
        'prevent': "Do not assume previously installed JDK persists across sessions.",
    },
    {
        'id': 'sdkmanager-corrupt-or-permission', 'severity': 'high', 'category': 'android-sdk', 'status': 'solved/workaround',
        'problem': "sdkmanager broken after partial commandline-tools extraction or missing executable bit.",
        'symptom': "sdkmanager: Permission denied; Could not find or load main class SdkManagerCli.",
        'root': "Interrupted extraction or copied files without chmod.",
        'solution': "chmod +x cmdline-tools/latest/bin/*; if class missing, re-extract commandline-tools cleanly.",
        'verify': "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --version",
        'prevent': "Treat SDK directory existence as insufficient; verify executable and classpath.",
    },
    {
        'id': 'ndk-source-properties-missing', 'severity': 'high', 'category': 'android-ndk', 'status': 'solved/workaround',
        'problem': "NDK directory exists but installation is incomplete.",
        'symptom': "NDK ... did not have a source.properties file.",
        'root': "Interrupted NDK download/extraction.",
        'solution': "Remove incomplete NDK and reinstall/re-extract; set ndkVersion in Gradle instead of ndk.dir.",
        'verify': "test -f $ANDROID_HOME/ndk/<version>/source.properties",
        'prevent': "Always verify source.properties before native build.",
    },
    {
        'id': 'compose-bom-icon-crash', 'severity': 'critical', 'category': 'kotlin-compose', 'status': 'solved',
        'problem': "Compose app crashes on launch from mismatched material-icons-extended version.",
        'symptom': "NoSuchMethodError: KeyframesSpec$KeyframesSpecConfig.at().",
        'root': "material-icons-extended pinned to old version while Compose BOM resolves other artifacts newer.",
        'solution': "Remove explicit material-icons-extended version; let BOM manage it, or replace icons with local vector drawables.",
        'verify': "grep material-icons gradle/libs.versions.toml; launch app/logcat no NoSuchMethodError.",
        'prevent': "All Compose artifacts must be BOM-aligned.",
    },
    {
        'id': 'android-appsfilter-blocked', 'severity': 'high', 'category': 'android-runtime', 'status': 'solved',
        'problem': "Android 11+ package visibility blocks file picker/DocumentsUI.",
        'symptom': "AppsFilter: BLOCKED; file picker cannot open.",
        'root': "Missing <queries> manifest declarations.",
        'solution': "Add queries for OPEN_DOCUMENT, CREATE_DOCUMENT, OPEN_DOCUMENT_TREE, and com.google.android.documentsui.",
        'verify': "grep -n '<queries>' app/src/main/AndroidManifest.xml; test file picker on device.",
        'prevent': "Any app using external intents must declare package visibility.",
    },
    {
        'id': 'material-icons-extended-size', 'severity': 'medium', 'category': 'apk-size', 'status': 'open/optimization',
        'problem': "Debug APK bloated by Material Icons Extended and unminified debug build.",
        'symptom': "15MB debug APK, multiple classes.dex files.",
        'root': "Huge icon library + debug/unshrunk Compose dependencies.",
        'solution': "Use release build with R8/shrinkResources; replace extended icons with small vector drawables where possible.",
        'verify': "Compare APK sizes and dex count before/after.",
        'prevent': "Avoid broad icon packs in size-sensitive APKs.",
    },
    {
        'id': 'kotlin-compose-compile-fixes', 'severity': 'medium', 'category': 'kotlin', 'status': 'solved patterns',
        'problem': "Common Kotlin/Compose compile errors in Android port.",
        'symptom': "Unresolved HorizontalDivider, FinishableInputStream, Byte==Int, rememberCoroutineScope/launch/withContext issues, LZMAInputStream overload mismatch.",
        'root': "API version differences, missing imports, wrong overloads, Byte/Int type strictness.",
        'solution': "Use Divider(), remove bad import, convert Byte to Int, import/use coroutine scope, call LZMAInputStream(bais).",
        'verify': "./gradlew compileDebugKotlin --no-daemon --max-workers=1",
        'prevent': "Port Kotlin incrementally and compile after grouped API fixes.",
    },
    {
        'id': 'apktool-offline-path', 'severity': 'critical', 'category': 'offline-apk', 'status': 'recommended',
        'problem': "Need to modify/build APK when Android SDK cannot be downloaded.",
        'symptom': "No SDK or no internet for Gradle dependencies.",
        'root': "Gradle Android source builds require SDK and cached dependencies.",
        'solution': "Use apktool decode/build and signer on existing APK. This avoids SDK/Gradle/NDK.",
        'verify': "apktool b succeeds; signed APK installs or `jar tf` shows valid APK contents.",
        'prevent': "Keep apktool and signer jars in /home/user/tools or repo tool cache.",
    },
    {
        'id': 'apk-structure-aware-compression', 'severity': 'medium', 'category': 'compression', 'status': 'learned design',
        'problem': "Compressing APK as opaque binary misses redundancy hidden by internal ZIP/DEFLATE entries.",
        'symptom': "Raw APK recompression loses to 7z/LZMA2 or gains little.",
        'root': "APK is already ZIP; internal entries may already be compressed.",
        'solution': "APK-aware preprocess: decompress internal entries, rebuild stored ZIP, compress with LZMA2, then restore original APK structure on decompression.",
        'verify': "SHA256-exact restored APK and benchmark vs raw 7z.",
        'prevent': "Use file-format-aware preprocessing for container formats.",
    },
    {
        'id': 'compression-roundtrip-required', 'severity': 'critical', 'category': 'compression', 'status': 'standing rule',
        'problem': "Compression improvements can silently corrupt data.",
        'symptom': "Round-trip failed; Expected N got M; SHA mismatch; BPE 6000->6118->5900; LZ77 lazy matching loses bytes.",
        'root': "Transforms were not independently reversible or container lacked boundaries.",
        'solution': "Every transform and pipeline must pass byte-exact/SHA256 round-trip tests; store compressed chunk lengths; flush pending matches; avoid buggy BPE/ARLE.",
        'verify': "sha256(original)==sha256(decompressed) across fuzz and real samples.",
        'prevent': "No compression ratio claim without round-trip verification.",
    },
    {
        'id': 'zarchiver-provider-protocol', 'severity': 'high', 'category': 'zarchiver', 'status': 'learned integration',
        'problem': "ZArchiver plugin compatibility requires exact provider protocol behavior.",
        'symptom': "Plugin not discovered or file operations fail.",
        'root': "ZArchiver uses custom discovery action, query columns, call() ops, and custom openFile modes.",
        'solution': "Use action ru.zdevs.zarchiver.plugin.PLUGIN_APPLICATION; exported provider no permission; support get=accounts, mkdir/rename/remove/disk/flush, w2/w4 mode sanitization.",
        'verify': "Test with actual ZArchiver app; query provider manually if possible.",
        'prevent': "Do not change provider authority/protocol without compatibility test.",
    },
]

now = datetime.now().astimezone().isoformat(timespec='seconds')

lines = []
lines.append('# AIOS Problem & Solution Database')
lines.append('')
lines.append(f'Generated by: `scripts/anylasis.sh`')
lines.append(f'Generated at: `{now}`')
lines.append('Scope: memory, reports, task files, instructions, scripts, docs, research, Agents, messages.')
lines.append('')
lines.append('> This file is the canonical `/anylasis` output. It stores actionable problems, root causes, fixes, verification steps, and prevention rules for future agents.')
lines.append('')
lines.append('## Executive Summary')
lines.append('')
lines.append(f'- Files scanned: **{len(files)}**')
lines.append(f'- Canonical problem entries: **{len(canonical)}**')
lines.append(f'- Evidence hits by category:')
for key in sorted(hits):
    lines.append(f'  - `{key}`: {len(hits[key])}')
lines.append('')

sev_order = {'critical':0, 'high':1, 'medium':2, 'low':3}
canon_sorted = sorted(canonical, key=lambda x: (sev_order.get(x['severity'], 9), x['category'], x['id']))

lines.append('## Top Critical Problems')
lines.append('')
for p in [x for x in canon_sorted if x['severity']=='critical']:
    lines.append(f"- **{p['id']}** ({p['category']}): {p['problem']} → {p['solution']}")
lines.append('')

lines.append('## Detailed Problem-Solution Table')
lines.append('')
lines.append('| ID | Severity | Category | Status | Problem | Root Cause | Solution | Verification | Prevention |')
lines.append('|---|---|---|---|---|---|---|---|---|')
for p in canon_sorted:
    def esc(s):
        return str(s).replace('|','\\|').replace('\n','<br>')
    lines.append(f"| `{p['id']}` | {esc(p['severity'])} | {esc(p['category'])} | {esc(p['status'])} | {esc(p['problem'])} | {esc(p['root'])} | {esc(p['solution'])} | `{esc(p['verify'])}` | {esc(p['prevent'])} |")
lines.append('')

# Standing command recipes
lines.append('## Reusable Command Recipes')
lines.append('')
lines.append('### Full-log build wrapper')
lines.append('```bash')
lines.append('cmd > build.log 2>&1')
lines.append('ec=$?')
lines.append('tail -100 build.log')
lines.append('exit $ec')
lines.append('```')
lines.append('')
lines.append('### Low-memory Gradle build')
lines.append('```bash')
lines.append('pkill -9 java 2>/dev/null || true')
lines.append('export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64')
lines.append('export PATH="$JAVA_HOME/bin:$PATH"')
lines.append('./gradlew assembleDebug --no-daemon --max-workers=1 > build.log 2>&1')
lines.append('```')
lines.append('')
lines.append('### No-SDK APKTool rebuild')
lines.append('```bash')
lines.append('java -jar /home/user/tools/apktool.jar d -f app.apk -o work_apk')
lines.append('# edit manifest/resources/smali')
lines.append('java -jar /home/user/tools/apktool.jar b work_apk -o rebuilt-unsigned.apk')
lines.append('java -jar /home/user/tools/uber-apk-signer.jar -a rebuilt-unsigned.apk --out signed')
lines.append('```')
lines.append('')

# Evidence appendix
lines.append('## Evidence Appendix')
lines.append('')
for key in sorted(hits):
    lines.append(f'### {key} ({len(hits[key])} hits)')
    for f, i, s in hits[key][:25]:
        s = s.replace('`', "'")
        lines.append(f'- `{f}:{i}` — {s}')
    if len(hits[key]) > 25:
        lines.append(f'- ... {len(hits[key])-25} more hits')
    lines.append('')

lines.append('## Next Recommended Actions')
lines.append('')
lines.append('1. If building Android source on this VM, first patch `gradle.properties` to the low-memory profile.')
lines.append('2. If Android SDK is unavailable/offline, use the APKTool path against existing APK artifacts.')
lines.append('3. Replace broad Material Icons Extended usage with vector drawables before release-size optimization.')
lines.append('4. Add a preflight script that checks Java, Gradle wrapper executable bit, ANDROID_HOME, SDK files, memory, and remote origin before builds.')
lines.append('5. After every task, run `bash scripts/anylasis.sh` and commit `memory/problem&solution.md` if changed.')
lines.append('')

out.write_text('\n'.join(lines) + '\n')
print(f'Wrote {out}')
print(f'Files scanned: {len(files)}')
print('Top evidence categories:')
for key, count in Counter({k: len(v) for k,v in hits.items()}).most_common(10):
    print(f'  {key}: {count}')
PY

echo "Generated: $OUT_FILE"
wc -l "$OUT_FILE"
