@Override
public void onWindowFocusChanged(boolean hasFocus) {
    super.onWindowFocusChanged(hasFocus);

    if (hasFocus && !wxStarted) {
        wxStarted = true;
        WxBridge.logInitCalled();   // <-- log Java
        WxBridge.initWx();          // chama JNI
    }
}
