package com.samsung.android.game.gos.service;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.RemoteException;
import android.os.ServiceManager;
import android.util.Log;
import com.samsung.android.game.gos.controller.GameManager;
import com.samsung.android.game.gos.policy.DisplayPolicy;
import com.samsung.android.game.gos.policy.DvfsManager;
import com.samsung.android.game.gos.policy.MemoryManagementPolicy;
import com.samsung.android.game.gos.policy.ThermalManager;
import com.samsung.android.os.SemProcessManager;

public class GosService extends Service {
    private static final String TAG = "GosService";
    private GameManager mGameManager;
    private DvfsManager mDvfsManager;
    private DisplayPolicy mDisplayPolicy;
    private ThermalManager mThermalManager;
    private MemoryManagementPolicy mMemoryPolicy;

    private final SemProcessManager.SemProcessListener mProcessListener = new SemProcessManager.SemProcessListener() {
        @Override
        public void onForegroundActivityChanged(String packageName, int pid) {
            Log.i(TAG, "onForegroundActivityChanged: " + packageName);
            if (mGameManager.isGamePackage(packageName)) {
                applyOptimizationPolicies(packageName);
            } else {
                restoreNormalPolicies();
            }
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "Initializing Game Optimization Service daemon...");
        mGameManager = GameManager.getInstance(this);
        mDvfsManager = DvfsManager.getInstance(this);
        mDisplayPolicy = DisplayPolicy.getInstance(this);
        mThermalManager = ThermalManager.getInstance(this);
        mMemoryPolicy = MemoryManagementPolicy.getInstance(this);

        SemProcessManager.registerListener(mProcessListener);
        ServiceManager.addService("gos_service", new GosServiceBinder(this));
    }

    private void applyOptimizationPolicies(String packageName) {
        mMemoryPolicy.cleanBackgroundProcesses();
        mDvfsManager.applyGovernorBoost(packageName);
        mDisplayPolicy.applyFramerateClamp(packageName);
        mThermalManager.startThermalMonitoring(packageName);
    }

    private void restoreNormalPolicies() {
        mDvfsManager.restoreDefaultGovernor();
        mDisplayPolicy.restoreDisplayDefaults();
        mThermalManager.stopThermalMonitoring();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return new GosServiceBinder(this);
    }
}
