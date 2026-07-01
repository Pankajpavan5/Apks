package com.rezuku.pk.ui.screens

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.rezuku.pk.R
import com.rezuku.pk.shizuku.ShizukuPermission
import com.rezuku.pk.shizuku.ShizukuStatus
import com.rezuku.pk.shizuku.starter.Starter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Top-level screen that mirrors the original Shizuku Manager home:
 *  - shows the current service status
 *  - exposes the four start paths: wireless ADB, ADB pairing, root, manual
 *
 * The actual start logic lives in `shizuku/starter/Starter`; this composable
 * just provides the buttons and surfaces the results.
 */
@Composable
fun HomeScreen(
    modifier: Modifier = Modifier,
    onStatusChange: (ShizukuStatus) -> Unit = {},
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var status by remember { mutableStateOf(ShizukuStatus.fromCurrent(context.packageManager)) }
    var lastMessage by remember { mutableStateOf<String?>(null) }
    var inFlight by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        // Refresh once on first composition; afterwards user actions drive updates.
        val pm = context.packageManager
        val next = withContext(Dispatchers.IO) { ShizukuStatus.fromCurrent(pm) }
        status = next
        onStatusChange(next)
    }

    val runStarter: (Starter.StartMethod) -> Unit = { method ->
        if (!inFlight) {
            inFlight = true
            scope.launch {
                lastMessage = runStart(method, context)
                status = ShizukuStatus.fromCurrent(context.packageManager)
                inFlight = false
            }
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        StatusCard(status = status, lastMessage = lastMessage)

        Text(
            text = stringResource(R.string.home_start_section),
            style = MaterialTheme.typography.titleMedium,
        )

        StartButton(
            labelRes = R.string.home_start_via_wireless_adb,
            enabled = !inFlight,
            onClick = { runStarter(Starter.StartMethod.WIRELESS_ADB) },
        )
        StartButton(
            labelRes = R.string.home_start_via_adb,
            enabled = !inFlight,
            onClick = { runStarter(Starter.StartMethod.ADB) },
        )
        StartButton(
            labelRes = R.string.home_start_via_root,
            outlined = true,
            enabled = !inFlight,
            onClick = { runStarter(Starter.StartMethod.ROOT) },
        )

        if (status == ShizukuStatus.ACTIVE && !ShizukuPermission.isPermissionGranted()) {
            Button(
                onClick = {
                    if (!inFlight) {
                        inFlight = true
                        // requestPermission is callback-based, not suspending — its result
                        // can arrive synchronously (e.g. already granted) or asynchronously
                        // (the user responding to Android's permission dialog). Only the
                        // callback should clear `inFlight`, otherwise the button re-enables
                        // itself before the real answer comes back.
                        ShizukuPermission.requestPermission { granted ->
                            lastMessage = context.getString(
                                if (granted) R.string.permission_granted else R.string.permission_denied
                            )
                            inFlight = false
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.home_authorize_this_app))
            }
        }
    }
}

@Composable
private fun StartButton(
    labelRes: Int,
    outlined: Boolean = false,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    val modifier = Modifier.fillMaxWidth()
    if (outlined) {
        OutlinedButton(onClick = onClick, enabled = enabled, modifier = modifier) {
            Text(stringResource(labelRes))
        }
    } else {
        Button(onClick = onClick, enabled = enabled, modifier = modifier) {
            Text(stringResource(labelRes))
        }
    }
}

@Composable
private fun StatusCard(status: ShizukuStatus, lastMessage: String?) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = when (status) {
                ShizukuStatus.ACTIVE -> MaterialTheme.colorScheme.primaryContainer
                else -> MaterialTheme.colorScheme.errorContainer
            },
        ),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Text(
                text = when (status) {
                    ShizukuStatus.ACTIVE -> stringResource(R.string.status_active)
                    ShizukuStatus.NOT_ACTIVE -> stringResource(R.string.status_not_active)
                    ShizukuStatus.NOT_INSTALLED -> stringResource(R.string.status_not_installed)
                },
                style = MaterialTheme.typography.titleMedium,
            )
            lastMessage?.let {
                Text(it, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

private suspend fun runStart(
    method: Starter.StartMethod,
    context: Context,
): String = withContext(Dispatchers.IO) {
    Starter.start(method, context).userMessage
}
