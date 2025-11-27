#include <jni.h>
#include <android/log.h>

#include <wx/wx.h>
#include "wx_app.h"

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO,  "WXAPP", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "WXAPP", __VA_ARGS__)

extern "C" JNIEXPORT void JNICALL
Java_org_qtproject_example_wxapp_WxBridge_initWx(JNIEnv* env, jclass)
{
    static bool initialized = false;

    LOGI("initWx JNI chamado (initialized=%d)", initialized);

    if (initialized) {
        LOGI("initWx já foi chamado antes, retornando.");
        return;
    }
    initialized = true;

    // instancia da sua wxApp
    wxApp::SetInstance(new MyApp());

    int argc = 1;
    char appName[] = "wxapp";
    char* argv[] = { appName, nullptr };

    LOGI("Chamando wxEntry...");
    wxEntry(argc, argv);
    LOGI("Retornou de wxEntry");
}

