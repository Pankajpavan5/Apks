package com.rezuku.pk.shizuku

import android.content.pm.PackageManager
import rikka.shizuku.Shizuku
import rikka.sui.Sui

/**
 * Singleton wrapper around the Shizuku permission lifecycle.
 *
 * Adapted from Canta's `ShizukuPermission` companion object — converted to a
 * regular singleton so the same instance can be registered as a listener with
 * the Shizuku API exactly once for the lifetime of the process.
 *
 * Call [attach] from Application.onCreate() before any UI code runs.
 */
object ShizukuPermission {

    private const val SHIZUKU_PERMISSION_REQUEST_CODE = 0xCA07A

    private val isSui: Boolean = Sui.init("com.rezuku.pk")
    private var binderStatus: Boolean = Shizuku.pingBinder()

    /**
     * Registers listener callbacks so [isReady] reflects the live state.
     * Safe to call multiple times — Shizuku deduplicates identical listeners.
     */
    fun attach() {
        Shizuku.addBinderDeadListener { binderStatus = false }
        Shizuku.addBinderReceivedListener { binderStatus = true }
    }

    /**
     * Returns true iff the user has granted this app the Shizuku permission
     * and the underlying binder is alive. Must be called from the main thread.
     */
    fun isReady(): Boolean = binderStatus &&
            !Shizuku.isPreV11() &&
            !Shizuku.shouldShowRequestPermissionRationale() &&
            (isSui || Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED)

    /**
     * Returns true iff the user has previously granted the Shizuku permission
     * but we have not yet verified that the binder is currently reachable.
     */
    fun isPermissionGranted(): Boolean =
        isSui || Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED

    /**
     * Triggers a permission prompt if needed, otherwise immediately invokes
     * [onResult] with the current grant state.
     *
     * Implementation note: Shizuku's `addRequestPermissionResultListener` accepts
     * a SAM listener. We declare it as an explicit `object` rather than a Kotlin
     * lambda so `this` is unambiguously bound to the listener instance — that
     * lets us remove exactly this listener after it fires.
     */
    fun requestPermission(onResult: (granted: Boolean) -> Unit) {
        if (!binderStatus || Shizuku.isPreV11() || Shizuku.shouldShowRequestPermissionRationale()) {
            onResult(false)
            return
        }
        if (isPermissionGranted()) {
            onResult(true)
            return
        }
        val listener = object : Shizuku.OnRequestPermissionResultListener {
            override fun onRequestPermissionResult(requestCode: Int, grantResult: Int) {
                if (requestCode == SHIZUKU_PERMISSION_REQUEST_CODE) {
                    onResult(grantResult == PackageManager.PERMISSION_GRANTED)
                    Shizuku.removeRequestPermissionResultListener(this)
                }
            }
        }
        Shizuku.addRequestPermissionResultListener(listener)
        Shizuku.requestPermission(SHIZUKU_PERMISSION_REQUEST_CODE)
    }
}
