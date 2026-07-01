package com.rezuku.pk.shizuku.adb

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.rezuku.pk.MainActivity
import com.rezuku.pk.R

/**
 * Foreground service that performs the ADB pairing dance.
 *
 * In the upstream Shizuku Manager this service runs the actual mDNS discovery
 * and pairing protocol. The combined project keeps the service so the manifest
 * still advertises a foreground component (required by Android 8+) and so the
 * pairing UI flow can start it. The heavy lifting of the protocol is out of
 * scope for this rewrite — see the upstream module for the real implementation.
 */
class AdbPairingService : Service() {

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val timeoutRunnable = Runnable { stopSelf() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureChannel()
        startForeground(NOTIFICATION_ID, buildNotification(), foregroundServiceType())
        // Pairing protocol itself would run here; the combined rewrite leaves the
        // actual socket/secret exchange to the upstream component. Returning
        // START_NOT_STICKY because the service is only useful while a pairing
        // session is active.
        //
        // FOREGROUND_SERVICE_TYPE_SHORT_SERVICE (API 34+) requires the service to
        // stop itself within ~3 minutes or the system throws and kills the process.
        // Since there's no real pairing protocol running yet to call stopSelf() on
        // completion, schedule a safety-net stop comfortably inside that window.
        handler.removeCallbacks(timeoutRunnable)
        handler.postDelayed(timeoutRunnable, SHORT_SERVICE_SAFETY_TIMEOUT_MS)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeoutRunnable)
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.adb_pairing_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                )
                nm.createNotificationChannel(channel)
            }
        }
    }

    private fun buildNotification(): Notification {
        val openIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.adb_pairing_channel_name))
            .setContentText(getString(R.string.adb_pairing_channel_desc))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(openIntent)
            .setOngoing(true)
            .build()
    }

    private fun foregroundServiceType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE
        } else 0
    }

    companion object {
        private const val CHANNEL_ID = "adb_pairing"
        private const val NOTIFICATION_ID = 1001

        // Comfortably under the ~3-minute system-enforced limit for
        // FOREGROUND_SERVICE_TYPE_SHORT_SERVICE on Android 14+.
        private const val SHORT_SERVICE_SAFETY_TIMEOUT_MS = 150_000L
    }
}
