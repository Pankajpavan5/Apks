package com.rezuku.pk.shizuku

import android.content.pm.PackageManager
import com.rezuku.pk.SHIZUKU_PACKAGE_NAME
import rikka.shizuku.Shizuku

/**
 * Tri-state representation of whether the user can actually use Shizuku.
 * Mirrors Canta's enum but exposes a `fromCurrent` factory that the UI
 * can call to query the live status.
 */
enum class ShizukuStatus {
    /** Shizuku is installed, the user has granted permission, and the binder is up. */
    ACTIVE,

    /** Shizuku is installed but the binder is not reachable (e.g. user hasn't started it). */
    NOT_ACTIVE,

    /** The Shizuku package is not installed at all. */
    NOT_INSTALLED;

    companion object {
        /**
         * Inspects the system to determine the current status. Safe to call from any thread;
         * uses the cached `pingBinder()` result for the binder check.
         */
        fun fromCurrent(packageManager: PackageManager): ShizukuStatus {
            return try {
                packageManager.getPackageInfo(SHIZUKU_PACKAGE_NAME, 0)
                if (Shizuku.pingBinder() && !Shizuku.isPreV11()) ACTIVE else NOT_ACTIVE
            } catch (e: PackageManager.NameNotFoundException) {
                NOT_INSTALLED
            }
        }
    }
}
