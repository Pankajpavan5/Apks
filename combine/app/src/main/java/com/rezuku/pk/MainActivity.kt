package com.rezuku.pk

import android.os.Build
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Apps
import androidx.compose.material.icons.filled.Build
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.rezuku.pk.shizuku.ShizukuStatus
import com.rezuku.pk.ui.RezukuTheme
import com.rezuku.pk.ui.screens.AppsScreen
import com.rezuku.pk.ui.screens.HomeScreen

const val SHIZUKU_PACKAGE_NAME = "moe.shizuku.privileged.api"
const val APP_NAME = "Rezuku"

class MainActivity : androidx.fragment.app.FragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            enableEdgeToEdge()
        }
        super.onCreate(savedInstanceState)
        setContent {
            RezukuTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background,
                ) {
                    RezukuApp()
                }
            }
        }
    }
}

private enum class Tab(val titleRes: Int) {
    Home(R.string.tab_home),
    Apps(R.string.tab_apps),
}

@Composable
private fun RezukuApp() {
    var currentTab by remember { mutableStateOf(Tab.Home) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = currentTab == Tab.Home,
                    onClick = { currentTab = Tab.Home },
                    icon = { Icon(Icons.Filled.Build, contentDescription = null) },
                    label = { Text(stringResource(Tab.Home.titleRes)) },
                )
                NavigationBarItem(
                    selected = currentTab == Tab.Apps,
                    onClick = { currentTab = Tab.Apps },
                    icon = { Icon(Icons.Filled.Apps, contentDescription = null) },
                    label = { Text(stringResource(Tab.Apps.titleRes)) },
                )
            }
        },
    ) { innerPadding ->
        when (currentTab) {
            Tab.Home -> HomeScreen(
                modifier = Modifier.padding(innerPadding),
                onStatusChange = { /* could surface a banner if status changed */ },
            )
            Tab.Apps -> AppsScreen(
                modifier = Modifier.padding(innerPadding),
                shizukuStatusProvider = { ShizukuStatus.fromCurrent(packageManager) },
            )
        }
    }
}
