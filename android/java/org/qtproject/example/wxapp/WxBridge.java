package org.qtproject.example.wxapp;

import android.util.Log;   // <-- adiciona isso

public class WxBridge {
    public static native void initWx();

    public static void logInitCalled() {
        Log.d("WXAPP", "WxBridge.logInitCalled() chamado");
    }
}
