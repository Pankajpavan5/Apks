package moe.shizuku.manager.debloat.util

import android.content.pm.PackageManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import moe.shizuku.manager.shell.Shell
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader

object ShizukuShell {

    suspend fun uninstallPackage(packageName: String): String {
        return withContext(Dispatchers.IO) {
            try {
                val process = Shizuku.newProcess(
                    arrayOf("pm", "uninstall", "--user", "0", packageName),
                    null,
                    null
                )
                val exitCode = process.waitFor()
                val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
                if (exitCode == 0) "Success" else "Failed: $output"
            } catch (e: Exception) {
                "Error: ${e.message}"
            }
        }
    }

    suspend fun restorePackage(packageName: String): String {
        return withContext(Dispatchers.IO) {
            try {
                val process = Shizuku.newProcess(
                    arrayOf("cmd", "package", "install-existing", packageName),
                    null,
                    null
                )
                val exitCode = process.waitFor()
                val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
                if (exitCode == 0) "Restored" else "Failed: $output"
            } catch (e: Exception) {
                "Error: ${e.message}"
            }
        }
    }

    fun hasShizukuPermission(): Boolean {
        return try {
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        } catch (e: Exception) {
            false
        }
    }
}
