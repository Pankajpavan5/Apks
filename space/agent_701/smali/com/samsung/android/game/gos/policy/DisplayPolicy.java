package com.samsung.android.game.gos.policy;

import android.content.Context;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
import android.os.ServiceManager;
import android.os.SystemProperties;
import android.util.Log;

public class DisplayPolicy {
    private static final String TAG = "DisplayPolicy";
    private static final int SF_TRANSACTION_DFS_CLAMP = 1034;
    private static final int SF_TRANSACTION_DRS_SCALE = 1035;
    private static DisplayPolicy sInstance;
    private Context mContext;

    private DisplayPolicy(Context context) { mContext = context; }

    public static synchronized DisplayPolicy getInstance(Context context) {
        if (sInstance == null) sInstance = new DisplayPolicy(context);
        return sInstance;
    }

    public void applyFramerateClamp(String packageName) {
        int targetFps = 60; // default DFS table lookup
        Log.i(TAG, "Applying Dynamic Frame Scale (DFS) clamp to " + targetFps + " FPS for " + packageName);
        SystemProperties.set("debug.fps.clamp", String.valueOf(targetFps));
        executeSurfaceFlingerTransaction(SF_TRANSACTION_DFS_CLAMP, targetFps);
    }

    public void forceEmergencyFramerateClamp(int emergencyFps) {
        Log.w(TAG, "Thermal emergency! Forcing DFS clamp to " + emergencyFps + " FPS");
        SystemProperties.set("debug.fps.clamp", String.valueOf(emergencyFps));
        executeSurfaceFlingerTransaction(SF_TRANSACTION_DFS_CLAMP, emergencyFps);
    }

    public void restoreDisplayDefaults() {
        Log.i(TAG, "Restoring normal SurfaceFlinger composition rates");
        SystemProperties.set("debug.fps.clamp", "120");
        executeSurfaceFlingerTransaction(SF_TRANSACTION_DFS_CLAMP, 120);
    }

    private void executeSurfaceFlingerTransaction(int transactionCode, int value) {
        IBinder flinger = ServiceManager.getService("SurfaceFlinger");
        if (flinger != null) {
            Parcel data = Parcel.obtain();
            Parcel reply = Parcel.obtain();
            try {
                data.writeInterfaceToken("android.ui.ISurfaceComposer");
                data.writeInt(value);
                flinger.transact(transactionCode, data, reply, 0);
            } catch (RemoteException e) {
                Log.e(TAG, "SurfaceFlinger IPC transaction failed", e);
            } finally {
                data.recycle();
                reply.recycle();
            }
        }
    }
}
