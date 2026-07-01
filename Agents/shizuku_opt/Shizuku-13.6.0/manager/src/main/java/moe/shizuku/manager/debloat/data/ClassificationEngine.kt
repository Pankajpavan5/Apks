package moe.shizuku.manager.debloat.data

import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo

object ClassificationEngine {

    private val recommendedPackages = setOf(
        "com.samsung.android.bixby.agent",
        "com.samsung.android.bixby.wakeup",
        "com.samsung.android.bixby.voiceinput",
        "com.samsung.android.bixbyvision.framework",
        "com.samsung.android.bixby.es.globalaction",
        "com.samsung.android.bixby.service",
        "com.samsung.android.bixby.plmsync",
        "com.samsung.android.bixbyvision.framework",
        "com.samsung.android.bixby.wakeup",
        "com.samsung.android.bixby.es.globalaction"
    )

    private val advancedPackages = setOf(
        "com.samsung.android.app.spage",
        "com.samsung.android.app.routines",
        "com.samsung.android.app.settings",
        "com.samsung.android.app.watchmanager",
        "com.samsung.android.app.watchmanagerstub"
    )

    private val expertPackages = setOf(
        "com.samsung.android.app.accessibilityassistant",
        "com.samsung.android.accessibility",
        "com.samsung.android.app.assistantmenu",
        "com.samsung.android.app.clipboardedge",
        "com.samsung.android.app.clipboardedge"
    )

    private val unsafePackages = setOf(
        "com.samsung.android.app.omcagent",
        "com.samsung.android.app.omcagent",
        "com.samsung.android.app.watchmanager",
        "com.samsung.android.bixby.agent"
    )

    fun classify(packageInfo: PackageInfo): PackageClassification {
        val appInfo = packageInfo.applicationInfo
        val packageName = packageInfo.packageName

        // Check if disabled
        if (!appInfo.enabled) {
            return PackageClassification.DISABLED
        }

        // Check by package name
        return when {
            recommendedPackages.contains(packageName) -> PackageClassification.RECOMMENDED
            advancedPackages.contains(packageName) -> PackageClassification.ADVANCED
            expertPackages.contains(packageName) -> PackageClassification.EXPERT
            unsafePackages.contains(packageName) -> PackageClassification.UNSAFE
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 -> PackageClassification.SYSTEM
            else -> PackageClassification.USER
        }
    }
}
