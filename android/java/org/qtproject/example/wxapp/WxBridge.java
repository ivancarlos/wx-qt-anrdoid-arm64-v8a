package org.qtproject.example.wxapp;

import android.util.Log;

public class WxBridge {
    public static native void initWx();

    // só pra debug se quiser
    public static void ping() {
        Log.d("WXAPP", "WxBridge.ping() chamado");
    }
}

