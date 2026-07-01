package moe.shizuku.manager.debloat

import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.TextView
import moe.shizuku.manager.R
import moe.shizuku.manager.app.AppBarActivity

class PackageInfoActivity : AppBarActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_package_info)

        val packageName = intent.getStringExtra("package_name") ?: return
        supportActionBar?.title = packageName

        loadPackageInfo(packageName)
    }

    private fun loadPackageInfo(packageName: String) {
        try {
            val pm = packageManager
            val pkgInfo = pm.getPackageInfo(packageName, PackageManager.GET_META_DATA)
            val appInfo = pkgInfo.applicationInfo

            findViewById<TextView>(R.id.tvAppName).text = appInfo.loadLabel(pm)
            findViewById<TextView>(R.id.tvPackageName).text = packageName
            findViewById<TextView>(R.id.tvVersion).text = "${pkgInfo.versionName} (${pkgInfo.versionCode})"
            findViewById<TextView>(R.id.tvUid).text = "UID: ${appInfo.uid}"
            findViewById<TextView>(R.id.tvInstallTime).text = "Installed: ${java.util.Date(pkgInfo.firstInstallTime)}"
            findViewById<TextView>(R.id.tvUpdateTime).text = "Updated: ${java.util.Date(pkgInfo.lastUpdateTime)}"
            findViewById<TextView>(R.id.tvTargetSdk).text = "Target SDK: ${appInfo.targetSdkVersion}"
            findViewById<TextView>(R.id.tvIsSystem).text = if ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) "System App" else "User App"
            findViewById<TextView>(R.id.tvEnabled).text = if (appInfo.enabled) "Enabled" else "Disabled"
        } catch (e: Exception) {
            findViewById<TextView>(R.id.tvAppName).text = "Error loading package info"
        }
    }
}
