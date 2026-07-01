package moe.shizuku.manager.debloat

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.widget.SearchView
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.tabs.TabLayout
import kotlinx.coroutines.launch
import moe.shizuku.manager.R
import moe.shizuku.manager.app.AppBarActivity
import moe.shizuku.manager.databinding.ActivityDebloatBinding
import moe.shizuku.manager.debloat.data.DebloatPackage
import moe.shizuku.manager.debloat.data.PackageClassification
import moe.shizuku.manager.debloat.ui.DebloatAdapter
import moe.shizuku.manager.debloat.ui.DebloatViewModel
import moe.shizuku.manager.debloat.ui.FilterBottomSheet
import moe.shizuku.manager.debloat.ui.LogsActivity
import moe.shizuku.manager.debloat.util.ShizukuShell

class DebloatActivity : AppBarActivity() {

    private lateinit var binding: ActivityDebloatBinding
    private lateinit var viewModel: DebloatViewModel
    private lateinit var adapter: DebloatAdapter

    private var isBatchMode = false
    private var currentTab = 0 // 0 = Installed, 1 = Recently Removed

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDebloatBinding.inflate(layoutInflater)
        setContentView(binding.root)

        supportActionBar?.title = "Rezuku"

        viewModel = DebloatViewModel(applicationContext)

        setupRecyclerView()
        setupTabs()
        setupSearch()
        setupObservers()
        setupBatchMode()

        // Load initial data
        viewModel.loadPackages()
    }

    private fun setupRecyclerView() {
        adapter = DebloatAdapter(
            onItemClick = { pkg -> showPackageInfo(pkg) },
            onCheckboxClick = { pkg, isChecked ->
                viewModel.toggleSelection(pkg.packageName, isChecked)
                updateBatchToolbar()
            },
            onLongClick = { pkg ->
                if (!isBatchMode) {
                    enterBatchMode()
                    viewModel.toggleSelection(pkg.packageName, true)
                    updateBatchToolbar()
                }
            }
        )

        binding.recyclerView.apply {
            layoutManager = LinearLayoutManager(this@DebloatActivity)
            adapter = this@DebloatActivity.adapter
        }
    }

    private fun setupTabs() {
        binding.tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab?) {
                currentTab = tab?.position ?: 0
                viewModel.setTab(currentTab)
            }
            override fun onTabUnselected(tab: TabLayout.Tab?) {}
            override fun onTabReselected(tab: TabLayout.Tab?) {}
        })
    }

    private fun setupSearch() {
        val searchView = binding.toolbar.menu.findItem(R.id.action_search).actionView as SearchView
        searchView.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(query: String?): Boolean = false
            override fun onQueryTextChange(newText: String?): Boolean {
                viewModel.setSearchQuery(newText ?: "")
                return true
            }
        })
    }

    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.packages.collect { packages ->
                adapter.submitList(packages)
                binding.emptyView.visibility = if (packages.isEmpty()) View.VISIBLE else View.GONE
            }
        }

        lifecycleScope.launch {
            viewModel.selectedCount.collect { count ->
                updateBatchToolbar(count)
            }
        }

        lifecycleScope.launch {
            viewModel.isLoading.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
            }
        }
    }

    private fun setupBatchMode() {
        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_search -> true
                R.id.action_filter -> {
                    showFilterDialog()
                    true
                }
                R.id.action_overflow -> {
                    showOverflowMenu()
                    true
                }
                else -> false
            }
        }
    }

    private fun updateBatchToolbar(count: Int = viewModel.selectedCount.value) {
        if (count > 0 && !isBatchMode) {
            enterBatchMode()
        } else if (count == 0 && isBatchMode) {
            exitBatchMode()
        }

        if (isBatchMode) {
            binding.toolbar.title = "$count selected"
            binding.toolbar.menu.clear()
            binding.toolbar.inflateMenu(R.menu.debloat_batch_menu)
        }
    }

    private fun enterBatchMode() {
        isBatchMode = true
        adapter.setBatchMode(true)
        binding.toolbar.menu.clear()
        binding.toolbar.inflateMenu(R.menu.debloat_batch_menu)
    }

    private fun exitBatchMode() {
        isBatchMode = false
        adapter.setBatchMode(false)
        viewModel.clearSelection()
        binding.toolbar.menu.clear()
        binding.toolbar.inflateMenu(R.menu.debloat_menu)
        binding.toolbar.title = "Rezuku"
    }

    private fun showPackageInfo(pkg: DebloatPackage) {
        val intent = Intent(this, PackageInfoActivity::class.java).apply {
            putExtra("package_name", pkg.packageName)
        }
        startActivity(intent)
    }

    private fun showFilterDialog() {
        FilterBottomSheet.newInstance { filters ->
            viewModel.setFilters(filters)
        }.show(supportFragmentManager, "filter")
    }

    private fun showOverflowMenu() {
        val popup = androidx.appcompat.widget.PopupMenu(this, findViewById(R.id.action_overflow))
        popup.menuInflater.inflate(R.menu.debloat_overflow_menu, popup.menu)
        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.menu_badge_info -> {
                    showBadgeInfo()
                    true
                }
                R.id.menu_logs -> {
                    startActivity(Intent(this, LogsActivity::class.java))
                    true
                }
                R.id.menu_settings -> {
                    // Open debloat settings
                    true
                }
                R.id.menu_presets -> {
                    showPresetsDialog()
                    true
                }
                R.id.menu_export -> {
                    viewModel.exportPackageList()
                    true
                }
                R.id.menu_refresh -> {
                    viewModel.loadPackages()
                    true
                }
                else -> false
            }
        }
        popup.show()
    }

    private fun showBadgeInfo() {
        val dialog = AlertDialog.Builder(this)
            .setTitle("Badge Info")
            .setMessage(
                "RECOMMENDED (Green): Safe to remove\n" +
                "ADVANCED (Yellow): Advanced users\n" +
                "EXPERT (Red): Expert only\n" +
                "UNSAFE (Purple): Risky to remove\n" +
                "SYSTEM (Dark Gray): System app\n" +
                "USER (Blue): User installed"
            )
            .setPositiveButton("OK", null)
            .create()
        dialog.show()
    }

    private fun showPresetsDialog() {
        val presets = arrayOf(
            "Samsung Debloat",
            "Google Debloat",
            "Privacy",
            "Battery",
            "Gaming",
            "Minimal"
        )
        AlertDialog.Builder(this)
            .setTitle("Presets")
            .setItems(presets) { _, which ->
                viewModel.applyPreset(presets[which])
            }
            .show()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.debloat_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                onBackPressed()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onBackPressed() {
        if (isBatchMode) {
            exitBatchMode()
        } else {
            super.onBackPressed()
        }
    }

    // Batch actions
    fun onBatchUninstall() {
        val selected = viewModel.getSelectedPackages()
        if (selected.isEmpty()) return

        AlertDialog.Builder(this)
            .setTitle("Remove selected packages?")
            .setMessage("This operation only removes apps for User 0.\nSystem partition remains unchanged.")
            .setPositiveButton("Uninstall") { _, _ ->
                performUninstall(selected)
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun performUninstall(packages: List<DebloatPackage>) {
        lifecycleScope.launch {
            packages.forEach { pkg ->
                val result = ShizukuShell.uninstallPackage(pkg.packageName)
                viewModel.logAction(pkg.packageName, result)
            }
            exitBatchMode()
            viewModel.loadPackages()
            Toast.makeText(this@DebloatActivity, "Uninstall completed", Toast.LENGTH_SHORT).show()
        }
    }

    fun onSelectAll() {
        viewModel.selectAll()
    }

    fun onCancelBatch() {
        exitBatchMode()
    }
}
