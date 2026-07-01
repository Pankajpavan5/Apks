# CMakeLists.txt for Rezuku — combined Canta + Shizuku Manager.
#
# Shizuku's manager module historically built a tiny native helper to talk to
# the adbd pairing protocol. The combined rewrite keeps the CMake target so the
# existing `externalNativeBuild { cmake { ... } }` block in `app/build.gradle.kts`
# resolves, but the actual native sources are intentionally minimal here. To
# re-enable the full pairing stack, copy the contents of
# `shizuku/manager/src/main/jni/` from the upstream repository into this
# directory.

cmake_minimum_required(VERSION 3.22.1)
project(rezuku LANGUAGES CXX)

# Stub target — produces an empty shared object so the APK packaging step
# succeeds. Drop in the real sources to re-enable native functionality.
add_library(rezuku_native SHARED
    rezuku_stub.cpp
)

target_compile_options(rezuku_native PRIVATE
    -std=c++17
    -fvisibility=hidden
    -Wall
    -Wextra
)

target_link_options(rezuku_native PRIVATE
    -Wl,--gc-sections
)
