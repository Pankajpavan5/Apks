# Rezuku

Combined Android project that fuses the **Shizuku Manager** service-starter
with the **Canta** app-management UI into a single APK under the package
name **`com.rezuku.pk`**.

> ⚠️ This project is a derivative of two upstream open-source projects:
>
> - **Canta** by samolego — licensed under **GPLv3**
>   <https://github.com/samolego/Canta>
> - **Shizuku (manager)** by RikkaApps — licensed under **Apache 2.0**
>   <https://github.com/RikkaApps/Shizuku>
>
> GPLv3 is a copyleft licence: any combined derivative distributed publicly
> must (a) carry the upstream `LICENSE` files, (b) provide complete
> corresponding source, and (c) itself be licensed under GPLv3. That is a
> legal obligation on the distributor, not a technical one — make sure you
> understand it before publishing an APK built from this tree.

## What's in here

```
combined/
├── app/
│   ├── build.gradle.kts          # Single-module Android app
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml   # Merged permissions from both projects
│       ├── java/com/rezuku/pk/
│       │   ├── RezukuApplication.kt
│       │   ├── MainActivity.kt           # Compose host w/ bottom nav
│       │   ├── data/SettingsStore.kt
│       │   ├── extension/PackageManagerExt.kt
│       │   ├── shizuku/
│       │   │   ├── ShizukuPermission.kt
│       │   │   ├── ShizukuStatus.kt
│       │   │   ├── ShizukuPackageInstallerUtils.kt
│       │   │   ├── adb/AdbPairingService.kt
│       │   │   └── starter/Starter.kt
│       │   ├── ui/
│       │   │   ├── RezukuTheme.kt
│       │   │   ├── screens/HomeScreen.kt     # Shizuku-side
│       │   │   ├── screens/AppsScreen.kt     # Canta-side
│       │   │   └── viewmodel/AppListViewModel.kt
│       │   └── util/apps/AppInfo.kt
│       ├── res/                  # strings, themes, icons
│       └── jni/                  # CMake stub (replace w/ upstream for full pairing)
├── build.gradle.kts
├── settings.gradle.kts
└── gradle.properties
```

## What the app does

- **Manager tab** — shows the current Shizuku service status; offers three
  start paths (wireless ADB, ADB pairing, root); exposes a button to grant
  the app Shizuku permission once the service is running.
- **Apps tab** — lists every installed package with its display name, package
  name, and a system-app badge. Has a search box and All / User / System
  filter chips. Tap rows to multi-select, then use the "Uninstall N
  selected" FAB — it shows a confirmation dialog, then drives a Shizuku-
  elevated uninstall (`com.android.shell`-owned `PackageInstaller`,
  `HiddenApiBypass` to reach the greylisted `uninstall(...)` overload) one
  package at a time, async-resolved via a local broadcast receiver. Results
  surface as a Snackbar; successfully-removed apps drop out of the list.

## What is intentionally *not* included

- **No banking-app-hiding feature.** The original task brief asked for a
  "hide from banking app" feature. This codebase does not contain such a
  feature and never will. Hiding an app's presence from another app's
  PackageManager queries is a capability pattern strongly associated with
  banking fraud tooling, and adding it would make the resulting APK unsafe
  to distribute.
- **Stub JNI.** The CMake target builds an empty `.so`. For real wireless
  ADB pairing copy the upstream `shizuku/manager/src/main/jni/` sources
  into `app/src/main/jni/` and rebuild.

## Review history

This codebase went through five static review passes (no Gradle execution
in this sandbox — see "Building" below):

| Pass | Focus                  | Key changes                                                              |
|------|------------------------|--------------------------------------------------------------------------|
| 1    | Bugs & dead code       | Removed unused `Settings` icon import; fixed ShizukuPermission listener leak (SAM lambda `this` ambiguity); replaced `by lazy` on mutable-derived `State` field |
| 2    | Optimisation           | Removed empty `attachBaseContext`; collapsed three near-identical Home buttons into a `StartButton` helper; tightened `ShizukuStatus.fromCurrent` signature |
| 3    | Robustness             | Removed unused imports across `AppsScreen` and `Starter`; wrapped `startService` in try/catch; passed `applicationContext` instead of activity Context into the ViewModel |
| 4    | Correctness            | Dropped unused `Context` parameter from `loadInstalled`; simplified `getAllPackagesInfo` to drop the broken `MATCH_UNINSTALLED_PACKAGES` filter; raised `minSdk` to 26 so the adaptive launcher icon resolves |
| 5    | Final polish           | Removed self-import in `ShizukuPermission.kt`; documented why `onTerminate` does not unregister the anonymous listeners; updated this README |
| 6    | Wire up uninstall + search/filter UI | Restored `HiddenApiBypass`-based `uninstall(...)` call in `ShizukuPackageInstallerUtils` (ported from upstream Canta, since the greylisted `IPackageInstaller` methods need it); added `Uninstaller.kt` to bridge the broadcast-based async result to a suspend fn; added `uninstallSelected`/`consumeUninstallResult` to the ViewModel; added search box, filter chips, confirm dialog, FAB, and Snackbar to `AppsScreen` |
| 7    | Static build audit (no SDK/network in this sandbox, so checks are static — not a verified compile) | **Real blockers found & fixed:** (1) `ShizukuPackageInstallerUtils.kt` referenced `android.content.pm.IPackageInstaller`/`IPackageManager`, hidden framework AIDL interfaces not in the public SDK — copied Canta's vendored compile-time stub `.java` files into `app/src/main/java/android/content/pm/`; without these the module would not compile at all. (2) `AndroidManifest.xml` declared `.shizuku.authorization.RequestPermissionActivity`, a class that was never ported into this tree — removed it (confirmed this app, as a Shizuku *client*, doesn't need it; that activity is manager-app-only, and upstream Canta's manifest doesn't declare it either). (3) Project shipped with no `gradlew`/`gradlew.bat`/`gradle-wrapper.jar` at all — `./gradlew` could not even start. Copied the wrapper script + jar from upstream Canta (version-locked safely; `gradle-wrapper.properties` already pinned this project to Gradle 8.7 and was left untouched). (4) `AdbPairingService` declared `FOREGROUND_SERVICE_TYPE_SHORT_SERVICE` but never stopped itself — added a safety-net `stopSelf()` timeout to avoid an Android 14+ system-enforced crash after ~3 minutes. (5) `HomeScreen.kt`'s "Authorize this app" button cleared its `inFlight` guard synchronously instead of inside the actual (possibly-async) permission-result callback — fixed so the button stays disabled until the real answer arrives. **Checked and confirmed sound (no changes needed):** every `R.string.*` reference in code resolves to a declared string; all manifest-declared component classes now exist; resource references (colors, mipmap, xml configs) all resolve; ProGuard rules correctly blanket-keep `com.rezuku.pk.**` and the Shizuku/HiddenApiBypass packages, and don't need to (and can't) keep platform classes like `PackageInstaller` since R8 never touches framework code; Gradle 8.7 + AGP 8.5.0 + JDK 17 toolchain are a compatible combination; `Starter.kt`'s blocking calls (`su -c` exec, `NetworkInterface` enumeration) are correctly dispatched via `Dispatchers.IO`, not on the main thread. |

## Building

This repository ships source code only. To produce an APK you need a normal
Android dev environment (Android Studio Iguana or newer, AGP 8.5, JDK 17,
Android SDK 36, NDK 26+):

```bash
cd combined
./gradlew :app:assembleDebug
```

The output APK will be at `app/build/outputs/apk/debug/app-debug.apk` and
will install as `com.rezuku.pk`.

To re-enable the full upstream Shizuku native pairing transport, replace
`app/src/main/jni/rezuku_stub.cpp` with the upstream `shizuku/manager/src/main/jni/`
sources and add the upstream CMake variables to `app/build.gradle.kts`'s
`externalNativeBuild { cmake { arguments = listOf(...) } }` block.

## Known follow-ups

These are deliberate gaps that the next contributor should fill:

1. **Root start that actually starts Shizuku.** The current `Starter.startViaRoot`
   only probes whether `su` is available; the real flow would shell out to
   `sh /data/adb/shizuku/start.sh` or equivalent.
2. **"Reset to factory" for updated system apps.** Canta's original
   `uninstallApp` first tries a no-flags uninstall to strip an updated system
   app back to its factory version before the real removal; the combined
   `Uninstaller` always uses `DELETE_SYSTEM_APP` directly and skips that step.
3. **Reinstall / `installExistingPackage` path.** Canta also supports
   reinstalling a previously-uninstalled-but-still-present system app; that
   half of `ShizukuPackageInstallerUtils` (`installExistingPackage`) was not
   ported over.
4. **No on-device or emulator test pass.** Everything above was written and
   statically reviewed in a sandbox with no Android SDK/emulator/network
   access — `./gradlew` itself could not be invoked, so "static audit passed"
   is not the same as "compiles." Run `./gradlew :app:assembleDebug` for
   real and test the uninstall flow on a device (ideally with Shizuku
   already running) before trusting it.
