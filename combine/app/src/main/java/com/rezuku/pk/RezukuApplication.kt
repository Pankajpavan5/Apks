package com.rezuku.pk

import android.app.Application
import com.rezuku.pk.data.SettingsStore
import com.rezuku.pk.shizuku.ShizukuPermission
import rikka.shizuku.Shizuku

/**
 * Application entry point for the combined app.
 *
 * Responsibilities:
 *  - Initialise the user-settings DataStore (carried over from Canta)
 *  - Register Shizuku lifecycle listeners so the rest of the app
 *    can react to "binder alive" / "binder dead" events
 */
class RezukuApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Persistent settings (presets, auto-update flag, etc.) - carried over from Canta.
        SettingsStore.initialize(applicationContext)

        // Bind Shizuku listener once. addBinderReceivedListener / addBinderDeadListener
        // are no-ops if the same listener was registered before, so this is safe across
        // process restarts as long as we use a stable singleton holder.
        ShizukuPermission.attach()
    }

    override fun onTerminate() {
        // Best-effort cleanup. Android does not guarantee this is called, and the
        // listeners we registered are anonymous lambdas (so we can't easily remove
        // them by reference). Leaving them registered is harmless because the
        // Application instance lives for the entire process lifetime.
        super.onTerminate()
    }
}
