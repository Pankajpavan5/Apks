package moe.shizuku.manager.shell.ui

import android.content.pm.PackageManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader

class ShellViewModel : ViewModel() {

    private val _shizukuStatus = MutableStateFlow(false)
    val shizukuStatus: StateFlow<Boolean> = _shizukuStatus.asStateFlow()

    private val _recentCommands = MutableStateFlow<List<String>>(listOf(
        "pm list packages -3",
        "dumpsys battery",
        "getprop | grep ro.product",
        "settings get global animator_duration_scale"
    ))
    val recentCommands: StateFlow<List<String>> = _recentCommands.asStateFlow()

    init {
        checkShizukuStatus()
    }

    fun checkShizukuStatus() {
        viewModelScope.launch {
            val connected = try {
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
            } catch (e: Exception) {
                false
            }
            _shizukuStatus.value = connected
        }
    }

    fun executeCommand(command: String) {
        viewModelScope.launch {
            try {
                val process = Shizuku.newProcess(arrayOf("sh", "-c", command), null, null)
                
                val output = StringBuilder()
                BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        output.appendLine(line)
                    }
                }
                
                // Add to recent commands (keep last 10)
                val current = _recentCommands.value.toMutableList()
                if (!current.contains(command)) {
                    current.add(0, command)
                    if (current.size > 10) current.removeLast()
                    _recentCommands.value = current
                }
                
            } catch (e: Exception) {
                // Error handling
            }
        }
    }
}
