package org.qtproject.example.wxapp;

import org.qtproject.qt5.android.bindings.QtActivity;
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends QtActivity {

    static {
        System.loadLibrary("wxapp");  // carrega libwxapp.so
    }

    private static boolean wxStarted = false;

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);

        if (hasFocus && !wxStarted) {
            wxStarted = true;
            Log.d("WXAPP", "MainActivity.onWindowFocusChanged: chamando initWx()");
            WxBridge.initWx();
        }
    }
}

