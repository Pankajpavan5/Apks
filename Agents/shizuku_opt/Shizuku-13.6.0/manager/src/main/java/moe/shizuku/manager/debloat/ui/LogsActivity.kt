package moe.shizuku.manager.debloat.ui

import android.os.Bundle
import android.widget.TextView
import moe.shizuku.manager.app.AppBarActivity

class LogsActivity : AppBarActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val textView = TextView(this).apply {
            setPadding(32, 32, 32, 32)
            textSize = 14f
        }
        setContentView(textView)
        supportActionBar?.title = "Logs"

        // In a real implementation, this would come from ViewModel
        textView.text = "Uninstall Logs\n\n" +
                "[2026-07-02 02:58] com.samsung.android.bixby.agent -> Success\n" +
                "[2026-07-02 02:57] com.samsung.android.app.spage -> Success\n" +
                "[2026-07-02 02:55] com.samsung.android.accessibility -> Failed: Permission denied"
    }
}
