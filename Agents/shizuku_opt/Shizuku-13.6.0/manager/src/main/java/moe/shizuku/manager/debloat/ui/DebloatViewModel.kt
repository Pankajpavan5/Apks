package moe.shizuku.manager.debloat.ui

import android.content.Context
import android.content.pm.PackageManager
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import moe.shizuku.manager.debloat.data.ClassificationEngine
import moe.shizuku.manager.debloat.data.DebloatPackage
import moe.shizuku.manager.debloat.data.PackageClassification
import java.text.SimpleDateFormat
import java.util.*

class DebloatViewModel(private val context: Context) : ViewModel() {

    private val _packages = MutableStateFlow<List<DebloatPackage>>(emptyList())
    val packages: StateFlow<List<DebloatPackage>> = _packages.asStateFlow()

    private val _selectedPackages = MutableStateFlow<MutableSet<String>>(mutableSetOf())
    val selectedCount = MutableStateFlow(0)

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private var currentTab = 0 // 0 = Installed, 1 = Recently Removed
    private var searchQuery = ""
    private var activeFilters = mutableSetOf<PackageClassification>()

    private val allPackages = mutableListOf<DebloatPackage>()
    private val removedPackages = mutableListOf<DebloatPackage>()
    private val logs = mutableListOf<String>()

    fun loadPackages() {
        viewModelScope.launch {
            _isLoading.value = true
            withContext(Dispatchers.IO) {
                try {
                    val pm = context.packageManager
                    val packages = pm.getInstalledPackages(PackageManager.GET_META_DATA)

                    allPackages.clear()
                    packages.forEach { pkgInfo ->
                        val classification = ClassificationEngine.classify(pkgInfo)
                        val debloatPkg = DebloatPackage.fromPackageInfo(pm, pkgInfo, classification)
                        allPackages.add(debloatPkg)
                    }
                    
                    // Simulate some removed packages for demo
                    removedPackages.clear()
                    removedPackages.addAll(allPackages.take(3))
                    
                    applyFiltersAndSearch()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            _isLoading.value = false
        }
    }

    fun setTab(tab: Int) {
        currentTab = tab
        applyFiltersAndSearch()
    }

    fun setSearchQuery(query: String) {
        searchQuery = query
        applyFiltersAndSearch()
    }

    fun setFilters(filters: Set<PackageClassification>) {
        activeFilters.clear()
        activeFilters.addAll(filters)
        applyFiltersAndSearch()
    }

    private fun applyFiltersAndSearch() {
        val sourceList = if (currentTab == 0) allPackages else removedPackages
        
        val filtered = sourceList.filter { pkg ->
            // Search filter
            val matchesSearch = searchQuery.isEmpty() ||
                pkg.appName.contains(searchQuery, ignoreCase = true) ||
                pkg.packageName.contains(searchQuery, ignoreCase = true)

            // Classification filter
            val matchesFilter = activeFilters.isEmpty() || activeFilters.contains(pkg.classification)

            matchesSearch && matchesFilter
        }.sortedBy { it.appName }

        _packages.value = filtered
    }

    fun toggleSelection(packageName: String, selected: Boolean) {
        if (selected) {
            _selectedPackages.value.add(packageName)
        } else {
            _selectedPackages.value.remove(packageName)
        }
        selectedCount.value = _selectedPackages.value.size
    }

    fun selectAll() {
        val currentList = _packages.value
        currentList.forEach { pkg ->
            _selectedPackages.value.add(pkg.packageName)
        }
        selectedCount.value = _selectedPackages.value.size
    }

    fun clearSelection() {
        _selectedPackages.value.clear()
        selectedCount.value = 0
    }

    fun getSelectedPackages(): List<DebloatPackage> {
        return allPackages.filter { _selectedPackages.value.contains(it.packageName) }
    }

    fun applyPreset(presetName: String) {
        val presetPackages = when (presetName) {
            "Samsung Debloat" -> allPackages.filter { it.packageName.contains("samsung", ignoreCase = true) }
            "Google Debloat" -> allPackages.filter { it.packageName.contains("google", ignoreCase = true) }
            "Privacy" -> allPackages.filter { it.classification == PackageClassification.EXPERT }
            "Battery" -> allPackages.filter { it.classification == PackageClassification.ADVANCED }
            "Gaming" -> allPackages.filter { it.classification == PackageClassification.RECOMMENDED }
            "Minimal" -> allPackages.filter { it.classification == PackageClassification.SYSTEM }.take(5)
            else -> emptyList()
        }
        
        _selectedPackages.value.clear()
        presetPackages.forEach { _selectedPackages.value.add(it.packageName) }
        selectedCount.value = _selectedPackages.value.size
    }

    fun logAction(packageName: String, result: String) {
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        logs.add("[$timestamp] $packageName -> $result")
    }

    fun getLogs(): List<String> = logs.toList()

    fun exportPackageList() {
        // TODO: Implement export functionality
    }
}
