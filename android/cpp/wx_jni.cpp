#include <jni.h>
#include <wx/wx.h>
#include <wx/app.h>
#include <wx/frame.h>

extern "C" JNIEXPORT void JNICALL
Java_org_qtproject_example_wxapp_WxBridge_initWx(JNIEnv*, jclass)
{
    static bool started = false;
    if (started)
        return;

    started = true;

    // Inicializa runtime wx (sem main loop)
    wxEntryStart(0, nullptr);

    // Inicia app
    wxTheApp->CallOnInit();
}

