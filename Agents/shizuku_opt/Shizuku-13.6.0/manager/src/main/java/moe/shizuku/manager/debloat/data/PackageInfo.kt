package moe.shizuku.manager.debloat.data

import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import java.io.File

data class DebloatPackage(
    val packageName: String,
    val appName: String,
    val versionName: String?,
    val versionCode: Long,
    val uid: Int,
    val installTime: Long,
    val updateTime: Long,
    val apkSize: Long,
    val isSystem: Boolean,
    val isEnabled: Boolean,
    val targetSdk: Int,
    val minSdk: Int,
    val classification: PackageClassification,
    val icon: android.graphics.drawable.Drawable? = null
) {
    companion object {
        fun fromPackageInfo(
            pm: PackageManager,
            packageInfo: PackageInfo,
            classification: PackageClassification
        ): DebloatPackage {
            val appInfo = packageInfo.applicationInfo
            val apkFile = File(appInfo.sourceDir)
            
            return DebloatPackage(
                packageName = packageInfo.packageName,
                appName = appInfo.loadLabel(pm).toString(),
                versionName = packageInfo.versionName,
                versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    packageInfo.versionCode.toLong()
                },
                uid = appInfo.uid,
                installTime = packageInfo.firstInstallTime,
                updateTime = packageInfo.lastUpdateTime,
                apkSize = if (apkFile.exists()) apkFile.length() else 0,
                isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0,
                isEnabled = appInfo.enabled,
                targetSdk = appInfo.targetSdkVersion,
                minSdk = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    appInfo.minSdkVersion
                } else 0,
                classification = classification
            )
        }
    }
}

enum class PackageClassification {
    RECOMMENDED,
    ADVANCED,
    EXPERT,
    UNSAFE,
    DISABLED,
    SYSTEM,
    USER,
    UNKNOWN
}
