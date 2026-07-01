package com.rezuku.pk.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rezuku.pk.R
import com.rezuku.pk.shizuku.ShizukuStatus
import com.rezuku.pk.ui.viewmodel.AppListViewModel
import com.rezuku.pk.util.apps.AppInfo
import com.rezuku.pk.util.apps.Filter

/**
 * App list + multi-select uninstall screen — the "Canta" half of the combined app.
 *
 * Search box + filter chips narrow [AppListViewModel.State.visibleApps]; tapping a row
 * toggles selection. A FAB appears once at least one app is selected, opens a confirm
 * dialog, then drives [AppListViewModel.uninstallSelected]. Results surface as a Snackbar.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppsScreen(
    modifier: Modifier = Modifier,
    shizukuStatusProvider: () -> ShizukuStatus,
    viewModel: AppListViewModel = viewModel(),
) {
    val context = LocalContext.current
    val activity = context as? android.app.Activity
    val state by viewModel.state.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var showConfirmDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadInstalled(context.packageManager)
    }

    LaunchedEffect(state.lastUninstallResult) {
        val result = state.lastUninstallResult ?: return@LaunchedEffect
        val message = when {
            result.failed.isEmpty() ->
                context.getString(R.string.apps_uninstall_result_success, result.succeeded.size)
            result.succeeded.isEmpty() ->
                context.getString(R.string.apps_uninstall_result_failure, result.failed.size)
            else ->
                context.getString(
                    R.string.apps_uninstall_result_partial,
                    result.succeeded.size,
                    result.failed.size,
                )
        }
        snackbarHostState.showSnackbar(message)
        viewModel.consumeUninstallResult()
    }

    if (showConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showConfirmDialog = false },
            title = {
                Text(
                    stringResource(
                        R.string.apps_uninstall_confirm_title,
                        state.selectedPackageNames.size,
                    )
                )
            },
            text = { Text(stringResource(R.string.apps_uninstall_confirm_message)) },
            confirmButton = {
                androidx.compose.material3.TextButton(onClick = {
                    showConfirmDialog = false
                    activity?.let { viewModel.uninstallSelected(it) }
                }) {
                    Text(stringResource(R.string.apps_uninstall_confirm_action))
                }
            },
            dismissButton = {
                androidx.compose.material3.TextButton(onClick = { showConfirmDialog = false }) {
                    Text(stringResource(R.string.apps_uninstall_cancel))
                }
            },
        )
    }

    Scaffold(
        modifier = modifier,
        snackbarHost = { SnackbarHost(snackbarHostState) { Snackbar(it) } },
        floatingActionButton = {
            if (state.selectedPackageNames.isNotEmpty() && !state.isUninstalling) {
                ExtendedFloatingActionButton(
                    onClick = { showConfirmDialog = true },
                    icon = { Icon(Icons.Filled.Delete, contentDescription = null) },
                    text = {
                        Text(
                            stringResource(
                                R.string.apps_uninstall_selected,
                                state.selectedPackageNames.size,
                            )
                        )
                    },
                )
            }
        },
    ) { scaffoldPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(scaffoldPadding),
        ) {
            BannerForShizukuStatus(status = shizukuStatusProvider())

            OutlinedTextField(
                value = state.searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text(stringResource(R.string.apps_search_placeholder)) },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 8.dp),
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                FilterChip(
                    selected = state.filter == Filter.any,
                    onClick = { viewModel.setFilter(Filter.any) },
                    label = { Text(stringResource(R.string.apps_filter_all)) },
                )
                FilterChip(
                    selected = state.filter == Filter.user,
                    onClick = { viewModel.setFilter(Filter.user) },
                    label = { Text(stringResource(R.string.apps_filter_user)) },
                )
                FilterChip(
                    selected = state.filter == Filter.system,
                    onClick = { viewModel.setFilter(Filter.system) },
                    label = { Text(stringResource(R.string.apps_filter_system)) },
                )
            }

            if (state.isLoading || state.isUninstalling) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        CircularProgressIndicator()
                        if (state.isUninstalling) {
                            Text(
                                text = stringResource(R.string.apps_uninstall_in_progress),
                                modifier = Modifier.padding(top = 12.dp),
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                    }
                }
                return@Column
            }

            if (state.visibleApps.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = stringResource(R.string.apps_empty_state),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                return@Column
            }

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                items(state.visibleApps, key = { it.packageName }) { app ->
                    AppRow(
                        app = app,
                        selected = app.packageName in state.selectedPackageNames,
                        onToggle = { viewModel.toggleSelection(app.packageName) },
                    )
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
private fun BannerForShizukuStatus(status: ShizukuStatus) {
    if (status == ShizukuStatus.ACTIVE) return
    val text = when (status) {
        ShizukuStatus.NOT_INSTALLED -> stringResource(R.string.banner_install_shizuku)
        ShizukuStatus.NOT_ACTIVE -> stringResource(R.string.banner_start_shizuku)
        ShizukuStatus.ACTIVE -> return
    }
    Surface(
        color = MaterialTheme.colorScheme.errorContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(16.dp),
            style = MaterialTheme.typography.bodyMedium,
        )
    }
}

@Composable
private fun AppRow(
    app: AppInfo,
    selected: Boolean,
    onToggle: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Checkbox(checked = selected, onCheckedChange = { onToggle() })

        Column(
            modifier = Modifier
                .padding(start = 8.dp)
                .weight(1f),
        ) {
            Text(
                text = app.name,
                style = MaterialTheme.typography.titleSmall,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                text = app.packageName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }

        if (app.isSystemApp) {
            Text(
                text = stringResource(R.string.app_badge_system),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.tertiary,
            )
        }
    }
}
