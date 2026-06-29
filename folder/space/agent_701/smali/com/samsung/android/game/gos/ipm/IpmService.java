package com.samsung.android.game.gos.ipm;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public class IpmService extends Service {
    private static final String TAG = "IpmService";
    private boolean mIsInitialized = false;

    static {
        System.loadLibrary("ipm");
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "Initializing Intelligent Performance Management (IPM) native AI layer...");
        mIsInitialized = nativeInitializeIpmModel("assets/models/ipm_target_model.tflite");
        if (mIsInitialized) {
            Log.i(TAG, "Successfully loaded TFLite thermal prediction neural network.");
        } else {
            Log.e(TAG, "Failed to initialize IPM native model.");
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && mIsInitialized) {
            String pkg = intent.getStringExtra("package");
            float frameTimeMs = intent.getFloatExtra("frametime", 16.6f);
            float currentTemp = intent.getFloatExtra("temp", 35.0f);
            float predictedTemp = nativePredictThermalSaturation(pkg, frameTimeMs, currentTemp);
            Log.i(TAG, "IPM Neural Network predicted equilibrium temp: " + predictedTemp + "°C for " + pkg);
        }
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    private native boolean nativeInitializeIpmModel(String tfliteModelPath);
    private native float nativePredictThermalSaturation(String packageName, float frameTimeMs, float currentTempCelsius);
}
