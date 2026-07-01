package com.rezuku.pk.util.apps

import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager

/**
 * One row in the apps list. Carries only the fields we actually render so we
 * don't keep full PackageInfo objects in memory.
 *
 * Derived from Canta's `AppInfo.fromPackageInfo`. Kept here under the
 * `com.rezuku.pk` namespace.
 */
data class AppInfo(
    val packageName: String,
    val name: String,
    val isSystemApp: Boolean,
    val isUninstalled: Boolean,
    val versionName: String?,
) {
    companion object {
        fun fromPackageInfo(info: PackageInfo, pm: PackageManager, uninstalled: Boolean): AppInfo {
            val appInfo: ApplicationInfo = info.applicationInfo
                ?: return AppInfo(
                    packageName = info.packageName,
                    name = info.packageName,
                    isSystemApp = false,
                    isUninstalled = uninstalled,
                    versionName = info.versionName,
                )
            val label = pm.getApplicationLabel(appInfo).toString()
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            return AppInfo(
                packageName = info.packageName,
                name = label,
                isSystemApp = isSystem,
                isUninstalled = uninstalled,
                versionName = info.versionName,
            )
        }
    }
}

/** Filter values used to slice the app list by category (system / user / all). */
enum class Filter { any, system, user, recommended;

    fun shouldShow(app: AppInfo): Boolean = when (this) {
        any -> true
        system -> app.isSystemApp
        user -> !app.isSystemApp
        recommended -> false // no recommendation list wired up yet
    }
}
