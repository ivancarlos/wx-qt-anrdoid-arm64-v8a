#include <jni.h>
#include <wx/wx.h>
#include <wx/app.h>
#include "wx_app.h"

extern "C" JNIEXPORT void JNICALL
Java_org_qtproject_example_wxapp_WxBridge_initWx(JNIEnv*, jclass)
{
    static bool initialized = false;
    if (initialized)
        return;

    initialized = true;

    wxApp::SetInstance(new MyApp());

    int argc = 1;
    char appName[] = "wxapp";
    char* argv[] = { appName, nullptr };

    wxEntry(argc, argv);
}

