package com.rezuku.pk.shizuku

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import androidx.core.content.ContextCompat
import rikka.shizuku.Shizuku
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCancellableCoroutine

/**
 * Drives a single privileged uninstall through [ShizukuPackageInstallerUtils] and
 * resolves once the system reports a final status.
 *
 * The underlying `IPackageInstaller.uninstall` call is fire-and-forget on its own —
 * the result arrives later as a broadcast Intent carrying `EXTRA_STATUS`. This class
 * registers a short-lived [BroadcastReceiver] for that one result and turns it into
 * a suspend call so the ViewModel can `await` each uninstall before moving to the next.
 */
object Uninstaller {

    private const val ACTION_UNINSTALL_RESULT = "com.rezuku.pk.UNINSTALL_RESULT"

    /**
     * Uninstalls [packageName]. Returns true if the system reported success
     * (`PackageInstaller.STATUS_SUCCESS`), false for any failure or exception.
     */
    suspend fun uninstall(
        activity: Activity,
        packageName: String,
        isSystemApp: Boolean,
    ): Boolean = suspendCancellableCoroutine { cont ->
        val context = activity.applicationContext
        var receiver: BroadcastReceiver? = null
        receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS,
                    PackageInstaller.STATUS_FAILURE,
                )
                context.unregisterReceiver(this)
                if (cont.isActive) cont.resume(status == PackageInstaller.STATUS_SUCCESS)
            }
        }

        val filter = IntentFilter(ACTION_UNINSTALL_RESULT)
        ContextCompat.registerReceiver(
            context,
            receiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )

        cont.invokeOnCancellation {
            runCatching { context.unregisterReceiver(receiver) }
        }

        try {
            val root = Shizuku.getUid() == 0
            val packageInstaller = ShizukuPackageInstallerUtils.getPackageInstaller(activity, root)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                packageName.hashCode(),
                Intent(ACTION_UNINSTALL_RESULT).setPackage(context.packageName),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            ShizukuPackageInstallerUtils.requestUninstall(
                packageInstaller,
                packageName,
                isSystemApp,
                pendingIntent.intentSender,
            )
        } catch (t: Throwable) {
            runCatching { context.unregisterReceiver(receiver) }
            if (cont.isActive) cont.resume(false)
        }
    }
}
