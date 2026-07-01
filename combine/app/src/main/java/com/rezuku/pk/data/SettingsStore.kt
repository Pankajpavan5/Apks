package com.rezuku.pk.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

/**
 * Persistent user preferences for the combined app.
 *
 * Slimmed down from Canta's SettingsStore: we keep only the keys we actually
 * read at runtime. Canta's original had bloat-list URLs, latest-commit hash,
 * auto-update flag, and per-preset config. We carry over `autoUpdateBloatList`
 * as a no-op flag so the code compiles cleanly even though the bloat list
 * itself is not fetched.
 */
private val Context.dataStore by preferencesDataStore(name = "rezuku_settings")

class SettingsStore private constructor(private val appContext: Context) {

    private object Keys {
        val AUTO_UPDATE_BLOAT_LIST = booleanPreferencesKey("auto_update_bloat_list")
        val LATEST_COMMIT_HASH = stringPreferencesKey("latest_commit_hash")
        val BLOAT_LIST_URL = stringPreferencesKey("bloat_list_url")
        val COMMITS_URL = stringPreferencesKey("commits_url")
    }

    val autoUpdateBloatListFlow: Flow<Boolean> =
        appContext.dataStore.data.map { it[Keys.AUTO_UPDATE_BLOAT_LIST] ?: false }

    val latestCommitHashFlow: Flow<String> =
        appContext.dataStore.data.map { it[Keys.LATEST_COMMIT_HASH] ?: "" }

    val bloatListUrlFlow: Flow<String> =
        appContext.dataStore.data.map { it[Keys.BLOAT_LIST_URL] ?: DEFAULT_BLOAT_LIST_URL }

    val commitsUrlFlow: Flow<String> =
        appContext.dataStore.data.map { it[Keys.COMMITS_URL] ?: DEFAULT_COMMITS_URL }

    suspend fun setAutoUpdateBloatList(value: Boolean) {
        appContext.dataStore.edit { it[Keys.AUTO_UPDATE_BLOAT_LIST] = value }
    }

    suspend fun setLatestCommitHash(value: String) {
        appContext.dataStore.edit { it[Keys.LATEST_COMMIT_HASH] = value }
    }

    suspend fun getLatestCommitHashBlocking(): String = latestCommitHashFlow.first()

    companion object {
        private const val DEFAULT_BLOAT_LIST_URL =
            "https://raw.githubusercontent.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/master/resources/uad_lists.json"
        private const val DEFAULT_COMMITS_URL =
            "https://api.github.com/repos/Universal-Debloater-Alliance/universal-android-debloater-next-generation/commits"

        @Volatile
        private var INSTANCE: SettingsStore? = null

        fun initialize(context: Context) {
            if (INSTANCE == null) {
                synchronized(this) {
                    if (INSTANCE == null) INSTANCE = SettingsStore(context.applicationContext)
                }
            }
        }

        fun getInstance(): SettingsStore =
            INSTANCE ?: error("SettingsStore.initialize(context) must be called first")
    }
}
