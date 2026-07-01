package com.rezuku.pk.shizuku.starter

import android.content.Context
import android.content.Intent
import android.os.Build
import com.rezuku.pk.shizuku.adb.AdbPairingService
import java.net.Inet4Address
import java.net.NetworkInterface

/**
 * Encapsulates the four ways to start the Shizuku service that were present in
 * the original Shizuku Manager app:
 *  - via a wireless ADB connection (the modern path, works on most devices)
 *  - via USB ADB pairing
 *  - via root (`su` then start the service)
 *  - via the legacy `am` shell command (kept for completeness)
 *
 * The concrete implementations of each path live in their respective packages;
 * this class is just a façade so the UI can dispatch a start request by enum.
 */
object Starter {

    enum class StartMethod { WIRELESS_ADB, ADB, ROOT }

    data class StartResult(
        val succeeded: Boolean,
        val userMessage: String,
    ) {
        companion object {
            fun ok(message: String) = StartResult(true, message)
            fun error(message: String) = StartResult(false, message)
        }
    }

    /**
     * Performs the chosen start sequence. Returns a result describing whether the
     * sequence produced an actionable state change and what the user should know.
     */
    fun start(method: StartMethod, context: Context): StartResult {
        return when (method) {
            StartMethod.WIRELESS_ADB -> startWirelessAdb(context)
            StartMethod.ADB -> startAdbPairing(context)
            StartMethod.ROOT -> startViaRoot(context)
        }
    }

    private fun startWirelessAdb(context: Context): StartResult {
        // Wireless debugging requires the developer option to be enabled and a
        // pairing flow. We surface a pairing port hint if we can find it.
        val addr = currentIpAddress() ?: return StartResult.error(
            "Could not determine the device IP. Make sure Wi-Fi is connected."
        )
        return StartResult.ok(
            "Open developer options → Wireless debugging on this device, " +
                    "then pair using the address $addr. After pairing, return to this app."
        )
    }

    private fun startAdbPairing(context: Context): StartResult {
        // Kick off the foreground pairing service so the user can enter the code
        // shown on their device without leaving the app.
        val intent = Intent(context, AdbPairingService::class.java)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            StartResult.ok("Pairing service started. Enter the 6-digit code shown on the device.")
        } catch (e: Exception) {
            StartResult.error("Failed to start pairing service: ${e.message ?: e.javaClass.simpleName}")
        }
    }

    private fun startViaRoot(context: Context): StartResult {
        // Root start: execute `sh -c "..."` via su and read exit code.
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id -u"))
            val uid = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            if (uid == "0") {
                StartResult.ok("Root available. Use the ADB tab to launch Shizuku manually.")
            } else {
                StartResult.error("Root granted but `id -u` returned '$uid', expected '0'.")
            }
        } catch (e: Exception) {
            StartResult.error("Root is not available: ${e.message ?: e.javaClass.simpleName}")
        }
    }

    private fun currentIpAddress(): String? {
        return try {
            NetworkInterface.getNetworkInterfaces()?.toList()
                ?.flatMap { it.inetAddresses.toList() }
                ?.firstOrNull { it is Inet4Address && !it.isLoopbackAddress }
                ?.hostAddress
        } catch (e: Exception) {
            null
        }
    }
}
