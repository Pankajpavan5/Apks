import gc
import sys
import os

def optimize_runtime():
    """
    Tuning the Python Virtual Machine for heavy AIOS tasks.
    - Disables automatic GC during tight loops to reduce overhead.
    - Sets recursion limit for deep analysis.
    - Optimizes memory allocation.
    """
    # 1. Increase recursion depth for deep research trees
    sys.setrecursionlimit(5000)
    
    # 2. Tune Garbage Collector
    # Increase thresholds to reduce frequency of Gen 0 collections
    # Default: (700, 10, 10) -> New: (2000, 15, 15)
    gc.set_threshold(2000, 15, 15)
    
    print("[Python-VM] Runtime optimized: GC thresholds raised, recursion depth increased.")

def enter_critical_section():
    """
    Disable GC for high-performance blocks (e.g., parsing 100s of video transcripts).
    Call this before a heavy loop and exit_critical_section() after.
    """
    gc.disable()
    print("[Python-VM] GC Disabled for critical section.")

def exit_critical_section():
    """
    Re-enable GC and force a full collection to reclaim memory.
    """
    gc.enable()
    gc.collect()
    print("[Python-VM] GC Enabled. Full collection performed.")

def memory_report():
    """
    Quick report of Python VM memory footprint.
    """
    import psutil
    process = psutil.Process(os.getpid())
    mem_info = process.memory_info()
    print(f"[Python-VM] RSS: {mem_info.rss / 1024**2:.2f} MB | VMS: {mem_info.vms / 1024**2:.2f} MB")

if __name__ == "__main__":
    optimize_runtime()
    memory_report()
