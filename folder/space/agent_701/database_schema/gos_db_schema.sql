-- SQLite Schema for Samsung GOS Database (/data/data/com.samsung.android.game.gos/databases/gos.db)

CREATE TABLE IF NOT EXISTS category_info (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL,
    description TEXT
);

INSERT INTO category_info VALUES (1, 'GAME', 'Application verified as a 3D/2D game subject to full optimization policies');
INSERT INTO category_info VALUES (2, 'NON_GAME', 'Application verified as a non-game utility/social app subject to thermal and framerate clamping');
INSERT INTO category_info VALUES (3, 'WHITELIST', 'Application verified as a benchmarking or critical system utility exempt from all throttling');
INSERT INTO category_info VALUES (4, 'VR', 'Virtual Reality heavy 3D application');
INSERT INTO category_info VALUES (5, 'SECURED', 'Samsung secure core apps');

CREATE TABLE IF NOT EXISTS game_package_info (
    package_name TEXT PRIMARY KEY,
    category INTEGER NOT NULL,
    drs_default INTEGER DEFAULT 90,
    dfs_default INTEGER DEFAULT 60,
    vrr_en INTEGER DEFAULT 1,
    siop_level INTEGER DEFAULT 1,
    ipm_target_temp INTEGER DEFAULT 41,
    custom_flags TEXT,
    FOREIGN KEY(category) REFERENCES category_info(category_id)
);

CREATE TABLE IF NOT EXISTS global_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

INSERT INTO global_settings VALUES ('game_mode_enabled', '1');
INSERT INTO global_settings VALUES ('alternate_game_perf_mode', '0');
INSERT INTO global_settings VALUES ('cloud_sync_timestamp', '1719657600');
INSERT INTO global_settings VALUES ('ipm_feature_enabled', '1');
