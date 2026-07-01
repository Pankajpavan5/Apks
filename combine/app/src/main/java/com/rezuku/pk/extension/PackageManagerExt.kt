package com.rezuku.pk.extension

import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import com.rezuku.pk.util.apps.AppInfo

/**
 * Extension helpers for enumerating installed packages.
 *
 * Simplified from Canta's `PackageManagerExt.kt`: we no longer chase the
 * MATCH_UNINSTALLED_PACKAGES flag for the "recently uninstalled" list, because
 * the semantics of that flag differ across Android versions and the feature is
 * not central to the combined app.
 */
fun PackageManager.getInstalledPackages(): List<PackageInfo> {
    val flags = PackageManager.GET_META_DATA
    // NOTE: the `getInstalledPackages(...)` calls below resolve to the real
    // `android.content.pm.PackageManager` member methods, not back to this extension
    // function — Kotlin always prefers a member over an extension with a matching
    // signature. Do not rename this extension to something that could shadow a
    // *different* member overload, or this becomes infinite recursion.
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        getInstalledPackages(PackageManager.PackageInfoFlags.of(flags.toLong()))
    } else {
        @Suppress("DEPRECATION")
        getInstalledPackages(flags)
    }
}

fun PackageManager.getAllPackagesInfo(): List<AppInfo> =
    getInstalledPackages().map { AppInfo.fromPackageInfo(it, this, uninstalled = false) }
