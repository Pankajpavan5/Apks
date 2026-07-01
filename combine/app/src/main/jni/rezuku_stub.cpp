// Stub native source — placeholder so the CMake build resolves. Replace with
// the upstream Shizuku pairing/transport sources if you need native ADB
// transport functionality.

#include <jni.h>

extern "C" JNIEXPORT jint JNICALL
JNI_OnLoad(JavaVM* /*vm*/, void* /*reserved*/) {
    return JNI_VERSION_1_6;
}
