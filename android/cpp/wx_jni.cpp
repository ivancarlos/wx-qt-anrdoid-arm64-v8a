#include "wx_app.h"
#include <android/log.h> // <-- adiciona
#include <jni.h>
#include <wx/app.h>
#include <wx/wx.h>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "WXAPP", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "WXAPP", __VA_ARGS__)

extern "C" JNIEXPORT void JNICALL
Java_org_qtproject_example_wxapp_WxBridge_initWx(JNIEnv *, jclass) {
  static bool initialized = false;

  LOGI("initWx JNI chamado (initialized=%d)", initialized);

  if (initialized)
    return;

  initialized = true;

  wxApp::SetInstance(new MyApp());

  int argc = 1;
  char appName[] = "wxapp";
  char *argv[] = {appName, nullptr};

  LOGI("Chamando wxEntry...");
  wxEntry(argc, argv);
  LOGI("Retornou de wxEntry");
}
