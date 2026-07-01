package com.rezuku.pk.ui.viewmodel

import android.app.Activity
import android.content.pm.PackageManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rezuku.pk.extension.getAllPackagesInfo
import com.rezuku.pk.shizuku.Uninstaller
import com.rezuku.pk.util.apps.AppInfo
import com.rezuku.pk.util.apps.Filter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.text.Collator
import java.util.Locale

/** Result of a batch uninstall, surfaced once so the UI can show a Snackbar and clear it. */
data class UninstallSummary(val succeeded: List<String>, val failed: List<String>)

/**
 * Holds the in-memory app list and exposes it as a [StateFlow] that the
 * Compose layer can collect.
 *
 * Behaviour carried over from Canta's AppListViewModel but simplified:
 *  - no bloat-list fetching (we don't ship uad_lists.json)
 *  - no per-app badge computation
 *  - selection is a Set<String> of package names
 */
class AppListViewModel : ViewModel() {

    data class State(
        val apps: List<AppInfo> = emptyList(),
        val selectedPackageNames: Set<String> = emptySet(),
        val searchQuery: String = "",
        val filter: Filter = Filter.any,
        val isLoading: Boolean = false,
        val isUninstalling: Boolean = false,
        val lastUninstallResult: UninstallSummary? = null,
    ) {
        /**
         * Derived list — recomputed eagerly on every read because the underlying
         * State instance is immutable and replaced when any input changes.
         * (A `by lazy` here would cache against the first State instance forever.)
         */
        val visibleApps: List<AppInfo>
            get() {
                val collator = Collator.getInstance(Locale.getDefault())
                return apps.asSequence()
                    .filter { filter.shouldShow(it) }
                    .filter {
                        searchQuery.isBlank() ||
                                it.name.contains(searchQuery, ignoreCase = true) ||
                                it.packageName.contains(searchQuery, ignoreCase = true)
                    }
                    .sortedWith(compareBy(collator, AppInfo::name))
                    .toList()
            }
    }

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    /**
     * Enumerates all installed packages on a background thread and publishes the
     * resulting list to [state]. Safe to call repeatedly; later calls re-scan.
     */
    fun loadInstalled(pm: PackageManager) {
        viewModelScope.launch {
            _state.value = _state.value.copy(isLoading = true)
            val list = withContext(Dispatchers.IO) { pm.getAllPackagesInfo() }
            _state.value = _state.value.copy(apps = list, isLoading = false)
        }
    }

    fun setSearchQuery(query: String) {
        _state.value = _state.value.copy(searchQuery = query)
    }

    fun setFilter(filter: Filter) {
        _state.value = _state.value.copy(filter = filter)
    }

    fun toggleSelection(packageName: String) {
        val current = _state.value.selectedPackageNames
        val next = if (packageName in current) current - packageName else current + packageName
        _state.value = _state.value.copy(selectedPackageNames = next)
    }

    fun clearSelection() {
        _state.value = _state.value.copy(selectedPackageNames = emptySet())
    }

    /**
     * Uninstalls every currently-selected package, one at a time (concurrent uninstalls
     * confuse the system installer session manager). Removes successfully-uninstalled
     * packages from [State.apps] and clears the selection. Publishes a [UninstallSummary]
     * to [State.lastUninstallResult] for the UI to show as a Snackbar; call
     * [consumeUninstallResult] once it has been shown.
     *
     * Requires an [Activity] because the underlying `PackageInstaller` construction
     * needs one on API < 31 — see [com.rezuku.pk.shizuku.ShizukuPackageInstallerUtils].
     */
    fun uninstallSelected(activity: Activity) {
        val targets = _state.value.apps.filter { it.packageName in _state.value.selectedPackageNames }
        if (targets.isEmpty()) return

        viewModelScope.launch {
            _state.value = _state.value.copy(isUninstalling = true)
            val succeeded = mutableListOf<String>()
            val failed = mutableListOf<String>()

            for (app in targets) {
                val ok = try {
                    Uninstaller.uninstall(activity, app.packageName, app.isSystemApp)
                } catch (t: Throwable) {
                    false
                }
                if (ok) succeeded += app.packageName else failed += app.packageName
            }

            _state.value = _state.value.copy(
                apps = _state.value.apps.filterNot { it.packageName in succeeded },
                selectedPackageNames = _state.value.selectedPackageNames - succeeded.toSet(),
                isUninstalling = false,
                lastUninstallResult = UninstallSummary(succeeded, failed),
            )
        }
    }

    fun consumeUninstallResult() {
        _state.value = _state.value.copy(lastUninstallResult = null)
    }
}
