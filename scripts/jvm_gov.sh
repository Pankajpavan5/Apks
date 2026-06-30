#!/usr/bin/env bash
# =============================================================================
# scripts/jvm_gov.sh — Dynamic JVM Resource Governor
# Optimizes heap and GC based on input file size to prevent OOM and reduce lag.
# Usage: bash scripts/jvm_gov.sh <tool_jar> <args> <target_file>
# =============================================================================
set -euo pipefail

JAR_FILE="$1"
shift
# The target file is the last argument
TARGET_FILE="${@: -1}"
# The actual tool arguments are everything in between
TOOL_ARGS="${@:1:${#@}-1}"

if [[ ! -f "$JAR_FILE" ]]; then
  echo "Error: Jar file $JAR_FILE not found."
  exit 1
fi

# 1. Calculate File Size in MB
FILE_SIZE_KB=$(du -k "$TARGET_FILE" | cut -f1)
FILE_SIZE_MB=$(( FILE_SIZE_KB / 1024 ))

# 2. Dynamic Heap Calculation
# Baseline: 256MB
# Scale: +2x File Size
# Cap: 1200MB (To leave room for OS/Python on 1.9GB VM)
HEAP_MB=$(( 256 + (FILE_SIZE_MB * 2) ))
if [ "$HEAP_MB" -gt 1200 ]; then
  HEAP_MB=1200
fi

# 3. GC Strategy Selection
# Large files -> G1GC (better for large heaps, reduces pauses)
# Small files -> ParallelGC (faster throughput, acceptable pauses)
if [ "$HEAP_MB" -gt 512 ]; then
  GC_OPTS="-XX:+UseG1GC -XX:G1HeapRegionSize=4m -XX:+UseStringDeduplication"
else
  GC_OPTS="-XX:+UseParallelGC -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
fi

echo "[JVM-Gov] File: $(basename "$TARGET_FILE") (${FILE_SIZE_MB}MB)"
echo "[JVM-Gov] Allocated Heap: ${HEAP_MB}MB | Strategy: ${GC_OPTS}"

# 4. Execute with optimized flags
java -Xmx${HEAP_MB}m -Xms${HEAP_MB}m $GC_OPTS -Djava.security.egd=file:/dev/urandom -jar "$JAR_FILE" $TOOL_ARGS "$TARGET_FILE"
