package org.qtproject.example.wxapp;

import org.qtproject.qt5.android.bindings.QtActivity;

public class MainActivity extends QtActivity {

    static {
        System.loadLibrary("wxapp");  // nossa lib nativa
    }

    private static boolean wxStarted = false;

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);

        if (hasFocus && !wxStarted) {
            wxStarted = true;
            WxBridge.initWx();   // chama JNI
        }
    }
}

