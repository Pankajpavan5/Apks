package com.samsung.android.game.gos.policy;

import android.content.Context;
import android.util.Log;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class ThermalManager {
    private static final String TAG = "ThermalManager";
    private static final String SYSFS_THERMAL_ZONE = "/sys/class/thermal/thermal_zone0/temp";
    private static ThermalManager sInstance;
    private Context mContext;

    public enum SiopLevel { NORMAL, WARNING, SEVERE, EMERGENCY }

    private ThermalManager(Context context) { mContext = context; }

    public static synchronized ThermalManager getInstance(Context context) {
        if (sInstance == null) sInstance = new ThermalManager(context);
        return sInstance;
    }

    public void startThermalMonitoring(String packageName) {
        int currentTemp = readThermalZoneTemp();
        Log.i(TAG, "Monitoring thermal envelope for " + packageName + ", temp: " + currentTemp);
        evaluateThermalPolicy(currentTemp);
    }

    public void evaluateThermalPolicy(int tempMillis) {
        int tempCelsius = tempMillis / 1000;
        if (tempCelsius >= 43) {
            enforceSiopLevel(SiopLevel.EMERGENCY);
        } else if (tempCelsius >= 41) {
            enforceSiopLevel(SiopLevel.SEVERE);
        } else if (tempCelsius >= 39) {
            enforceSiopLevel(SiopLevel.WARNING);
        } else {
            enforceSiopLevel(SiopLevel.NORMAL);
        }
    }

    private void enforceSiopLevel(SiopLevel level) {
        Log.w(TAG, "Enforcing SIOP Thermal Level: " + level.name());
        nativeSetTcmThermalLevel(level.ordinal());
        if (level == SiopLevel.EMERGENCY) {
            DisplayPolicy.getInstance(mContext).forceEmergencyFramerateClamp(30);
            DvfsManager.getInstance(mContext).clampGpuPowerLevel(3);
        } else if (level == SiopLevel.SEVERE) {
            DisplayPolicy.getInstance(mContext).forceEmergencyFramerateClamp(48);
            DvfsManager.getInstance(mContext).clampGpuPowerLevel(2);
        }
    }

    private int readThermalZoneTemp() {
        try (BufferedReader br = new BufferedReader(new FileReader(SYSFS_THERMAL_ZONE))) {
            return Integer.parseInt(br.readLine().trim());
        } catch (IOException | NumberFormatException e) {
            Log.e(TAG, "Failed to read kernel thermal zone", e);
            return 35000; // Fallback default
        }
    }

    public void stopThermalMonitoring() {
        nativeSetTcmThermalLevel(SiopLevel.NORMAL.ordinal());
    }

    private native void nativeSetTcmThermalLevel(int levelOrdinal);
}
