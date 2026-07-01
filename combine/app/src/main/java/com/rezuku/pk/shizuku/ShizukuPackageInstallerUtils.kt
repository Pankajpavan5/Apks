package com.rezuku.pk.shizuku

import android.app.Activity
import android.content.Context
import android.content.pm.IPackageInstaller
import android.content.pm.IPackageManager
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.os.Build
import org.lsposed.hiddenapibypass.HiddenApiBypass
import rikka.shizuku.ShizukuBinderWrapper
import rikka.shizuku.SystemServiceHelper
import java.lang.reflect.InvocationTargetException

/**
 * Wraps the system PackageInstaller / PackageManager so we can call them through
 * Shizuku's elevated binder. This is the core piece of plumbing that lets a
 * non-root app perform `pm uninstall` and `pm install-existing` operations.
 *
 * Ported from Canta's `ShizukuPackageInstallerUtils.kt`, which itself credits
 * <https://github.com/depau/fdroid_shizuku_privileged_extension> and a Shizuku-API
 * demo by RikkaW for the reflective `PackageInstaller` constructor lookup. Kept
 * under the combined `com.rezuku.pk.shizuku` namespace.
 *
 * `HiddenApiBypass` is required here (unlike elsewhere in this codebase) because
 * `IPackageInstaller.uninstall(...)` and `installExistingPackage(...)` are
 * `@SystemApi`/greylisted methods on API 28+; calling them via plain reflection
 * without the bypass throws `NoSuchMethodException` on those OS versions.
 */
object ShizukuPackageInstallerUtils {

    private val packageManager: IPackageManager by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            HiddenApiBypass.addHiddenApiExemptions("Landroid/content/pm")
        }
        IPackageManager.Stub.asInterface(
            ShizukuBinderWrapper(SystemServiceHelper.getSystemService("package"))
        )
    }

    fun getPrivilegedPackageInstaller(): IPackageInstaller =
        IPackageInstaller.Stub.asInterface(
            ShizukuBinderWrapper(packageManager.packageInstaller.asBinder())
        )

    /**
     * Constructs a PackageInstaller bound to a specific installer package name.
     * On API 26+ the constructor no longer needs the calling Activity context.
     */
    @Throws(
        NoSuchMethodException::class,
        IllegalAccessException::class,
        InvocationTargetException::class,
        InstantiationException::class,
    )
    fun createPackageInstaller(
        installer: IPackageInstaller?,
        installerPackageName: String?,
        userId: Int,
        activity: Activity,
    ): PackageInstaller {
        return when {
            Build.VERSION.SDK_INT > Build.VERSION_CODES.R -> PackageInstaller::class.java
                .getConstructor(
                    IPackageInstaller::class.java,
                    String::class.java,
                    String::class.java,
                    Int::class.javaPrimitiveType,
                )
                .newInstance(installer, installerPackageName, null, userId)

            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> PackageInstaller::class.java
                .getConstructor(IPackageInstaller::class.java, String::class.java, Int::class.java)
                .newInstance(installer, installerPackageName, userId)

            else -> PackageInstaller::class.java
                .getConstructor(
                    Context::class.java,
                    PackageManager::class.java,
                    IPackageInstaller::class.java,
                    String::class.java,
                    Int::class.javaPrimitiveType,
                )
                .newInstance(activity, activity.packageManager, installer, installerPackageName, userId)
        }
    }

    /**
     * Builds a [PackageInstaller] suitable for uninstall calls from [activity].
     *
     * Uses `com.android.shell` as the installer package name because the system's
     * `getMySessions` check looks at the installer package's owning UID, and `shell`
     * is what both ADB-paired and rooted Shizuku sessions run as.
     */
    fun getPackageInstaller(activity: Activity, root: Boolean): PackageInstaller {
        val iPackageInstaller = getPrivilegedPackageInstaller()
        val userId = if (root) android.os.Process.myUserHandle().hashCode() else 0
        return createPackageInstaller(iPackageInstaller, "com.android.shell", userId, activity)
    }

    /**
     * Uninstalls [packageName] via the privileged installer. [isSystemApp] selects the
     * uninstall flags: system apps need `DELETE_SYSTEM_APP` (0x4) so the system actually
     * removes the package rather than just hiding the user-data overlay; regular apps use
     * `DELETE_ALL_USERS` (0x2).
     *
     * The actual async result arrives at whatever `IntentSender` the caller passes in
     * (typically a `PendingIntent.getBroadcast` registered for a local `BroadcastReceiver`) —
     * this call only confirms the uninstall *request* was accepted, not that it completed.
     */
    @Throws(Exception::class)
    fun requestUninstall(
        packageInstaller: PackageInstaller,
        packageName: String,
        isSystemApp: Boolean,
        statusReceiver: android.content.IntentSender,
    ) {
        val flags = if (isSystemApp) 0x00000004 else 0x00000002
        HiddenApiBypass.invoke(
            PackageInstaller::class.java,
            packageInstaller,
            "uninstall",
            packageName,
            flags,
            statusReceiver,
        )
    }
}
