```{bash}
$ ls
dialogs.cpp  dialogs.h  Makefile  minimal.pro  sample.xpm  tip.xpm
ivan*:  /workspace/kiko/wx-qt-anrdoid-arm64-v8a main
$ make env
QT_VERSION       = 5.15.2
QT_ANDROID_DIR   = /home/ivan/.config/env/qt/5.15.2/android
QMAKE            = /home/ivan/.config/env/qt/5.15.2/android/bin/qmake
ANDROIDDEPLOYQT  = /home/ivan/.config/env/qt/5.15.2/android/bin/androiddeployqt
QT_ARCH          = arm64-v8a
WX_ANDROID_ROOT  = /home/ivan/wx/android-wx-3.2.4
ANDROID_SDK_ROOT = /home/ivan/Android/Sdk
ANDROID_NDK_ROOT = /home/ivan/Android/Sdk/ndk/android-ndk-r21e
ivan*:  /workspace/kiko/wx-qt-anrdoid-arm64-v8a main
$ make
abi         build       configure   install     logcat      uninstall
all         clean       env         kill        run
apk         clear-data  info        log2        sdk
ivan*:  /workspace/kiko/wx-qt-anrdoid-arm64-v8a main
$ make info
==========================================
  VARIÁVEIS DE AMBIENTE / BUILD
==========================================

📦 Qt:
  QT_VERSION       = 5.15.2
  QT_ANDROID_DIR   = /home/ivan/.config/env/qt/5.15.2/android
  QMAKE            = /home/ivan/.config/env/qt/5.15.2/android/bin/qmake
  ANDROIDDEPLOYQT  = /home/ivan/.config/env/qt/5.15.2/android/bin/androiddeployqt

🤖 Android SDK/NDK:
  ANDROID_SDK_ROOT = /home/ivan/Android/Sdk
  ANDROID_NDK_ROOT = /home/ivan/Android/Sdk/ndk/android-ndk-r21e
  ANDROID_NDK_PLATFORM = android-28
  BUILD_TOOLS_VER  = 36.1.0
  AAPT             = /home/ivan/Android/Sdk/build-tools/36.1.0/aapt

🔧 Build:
  PROJECT_ROOT     = /workspace/kiko/wx-qt-anrdoid-arm64-v8a
  BUILD_DIR        = /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build
  LIB_NAME         = libwxapp_arm64-v8a.so
  ANDROID_LIB_DIR  = /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build/android/libs/arm64-v8a
  DEPLOY_JSON      = android-wxapp-deployment-settings.json

📱 APKs:
  apk_debug        = build/android/build/outputs/apk/debug/android-debug.apk
  apk_release      = build/android/build/outputs/apk/release/android-release.apk
  APK (ativo)      = build/android/build/outputs/apk/debug/android-debug.apk

📲 Device Info (se APK existir):
  PACKAGE          =
  ACTIVITYNAME     =

ivan*:  /workspace/kiko/wx-qt-anrdoid-arm64-v8a main
$ make apk
QT_VERSION       = 5.15.2
QT_ANDROID_DIR   = /home/ivan/.config/env/qt/5.15.2/android
QMAKE            = /home/ivan/.config/env/qt/5.15.2/android/bin/qmake
ANDROIDDEPLOYQT  = /home/ivan/.config/env/qt/5.15.2/android/bin/androiddeployqt
QT_ARCH          = arm64-v8a
WX_ANDROID_ROOT  = /home/ivan/wx/android-wx-3.2.4
ANDROID_SDK_ROOT = /home/ivan/Android/Sdk
ANDROID_NDK_ROOT = /home/ivan/Android/Sdk/ndk/android-ndk-r21e
==> Gerando Makefile Android em /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build...
cd "/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build" && \
        "/home/ivan/.config/env/qt/5.15.2/android/bin/qmake" -makefile ../minimal.pro \
                WX_ANDROID_ROOT="/home/ivan/wx/android-wx-3.2.4" \
                QT_ARCH="arm64-v8a"
Info: creating stash file /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build/.qmake.stash
Project MESSAGE: WX_ANDROID_ROOT = /home/ivan/wx/android-wx-3.2.4
Project MESSAGE: QT_ARCH = arm64-v8a
Project MESSAGE: Compilando para Android (NDK)
Project MESSAGE: SYSROOT = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr
Project MESSAGE: Usando WX_CONFIG = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/bin/wx-config
Project MESSAGE: WX_CFLAGS = -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/wx/include/qt-unicode-3.2 -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2 -DWXUSINGDLL -D__WXQT__ -DQT_CORE_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_OPENGL_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_TESTLIB_LIB -DQT_CORE_LIB -D_FILE_OFFSET_BITS=64 -pthread
Project MESSAGE: WX_LIB_DIR = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib
Project MESSAGE: WX_ANDROID_ROOT = /home/ivan/wx/android-wx-3.2.4
Project MESSAGE: QT_ARCH = arm64-v8a
Project MESSAGE: Compilando para Android (NDK)
Project MESSAGE: SYSROOT = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr
Project MESSAGE: Usando WX_CONFIG = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/bin/wx-config
Project MESSAGE: WX_CFLAGS = -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/wx/include/qt-unicode-3.2 -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2 -DWXUSINGDLL -D__WXQT__ -DQT_CORE_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_OPENGL_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_TESTLIB_LIB -DQT_CORE_LIB -D_FILE_OFFSET_BITS=64 -pthread
Project MESSAGE: WX_LIB_DIR = /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib
[OK] Makefile gerado.
==> Compilando projeto (arm64-v8a)...
cd "/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build" && make
make[1]: Entrando no diretório '/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build'
/home/ivan/Android/Sdk/ndk/android-ndk-r21e/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++ -c -target aarch64-linux-android28 -fno-limit-debug-info -fPIC -fstack-protector-strong -DANDROID -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/wx/include/qt-unicode-3.2 -I/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2 -DWXUSINGDLL -D__WXQT__ -DQT_CORE_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_OPENGL_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -DQT_TESTLIB_LIB -DQT_CORE_LIB -D_FILE_OFFSET_BITS=64 -pthread -O2 -Wall -W -D_REENTRANT -fPIC -D__WXQT__ -DQT_NO_DEBUG -DQT_OPENGL_LIB -DQT_SVG_LIB -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_TESTLIB_LIB -DQT_CORE_LIB -DQT_TESTCASE_BUILDDIR='"/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build"' -I../../wx-qt-anrdoid-arm64-v8a -I. -I/home/ivan/.config/env/qt/5.15.2/android/include -I/home/ivan/.config/env/qt/5.15.2/android/include/QtOpenGL -I/home/ivan/.config/env/qt/5.15.2/android/include/QtSvg -I/home/ivan/.config/env/qt/5.15.2/android/include/QtWidgets -I/home/ivan/.config/env/qt/5.15.2/android/include/QtGui -I/home/ivan/.config/env/qt/5.15.2/android/include/QtTest -I/home/ivan/.config/env/qt/5.15.2/android/include/QtCore -Iarm64-v8a -I/home/ivan/.config/env/qt/5.15.2/android/mkspecs/android-clang -o arm64-v8a/dialogs.o ../dialogs.cpp
In file included from ../dialogs.cpp:1:
In file included from /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2/wx/wx.h:15:
In file included from /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2/wx/object.h:19:
In file included from /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2/wx/memory.h:15:
In file included from /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2/wx/string.h:36:
/home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/include/wx-3.2/wx/wxcrtbase.h:627:6: warning: "Custom mb/wchar conv. only works for ASCII, see Android NDK notes" [-W#warnings]
    #warning "Custom mb/wchar conv. only works for ASCII, see Android NDK notes"
     ^
1 warning generated.
/home/ivan/Android/Sdk/ndk/android-ndk-r21e/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++ -target aarch64-linux-android28 -fno-limit-debug-info -Wl,-soname,libwxapp_arm64-v8a.so -Wl,--build-id=sha1 -Wl,--no-undefined -Wl,-z,noexecstack -shared -o libwxapp_arm64-v8a.so arm64-v8a/dialogs.o   -llog /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/libwx_qtu_core-3.2-Android_arm64-v8a.so /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/libwx_baseu-3.2-Android_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5OpenGL_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5Svg_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5Widgets_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5Gui_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5Test_arm64-v8a.so /home/ivan/.config/env/qt/5.15.2/android/lib/libQt5Core_arm64-v8a.so -lGLESv2   -llog -lz -lm -ldl -lc
make[1]: Saindo do diretório '/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build'
[OK] Build concluído.
==> Preparando biblioteca para androiddeployqt...
# Copia a lib principal do app
   Copiado libwxapp_arm64-v8a.so -> /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build/android/libs/arm64-v8a/
# Copia as bibliotecas do wxWidgets necessárias
==> Copiando bibliotecas wxWidgets para o APK...
   Conteúdo de /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build/android/libs/arm64-v8a:
libwxapp_arm64-v8a.so
libwx_baseu-3.2-Android_arm64-v8a.so
libwx_baseu_net-3.2-Android_arm64-v8a.so
libwx_baseu_xml-3.2-Android_arm64-v8a.so
libwx_qtu_adv-3.2-Android_arm64-v8a.so
libwx_qtu_aui-3.2-Android_arm64-v8a.so
libwx_qtu_core-3.2-Android_arm64-v8a.so
libwx_qtu_html-3.2-Android_arm64-v8a.so
libwx_qtu_media-3.2-Android_arm64-v8a.so
libwx_qtu_propgrid-3.2-Android_arm64-v8a.so
libwx_qtu_qa-3.2-Android_arm64-v8a.so
libwx_qtu_ribbon-3.2-Android_arm64-v8a.so
libwx_qtu_richtext-3.2-Android_arm64-v8a.so
libwx_qtu_stc-3.2-Android_arm64-v8a.so
libwx_qtu_xrc-3.2-Android_arm64-v8a.so
==> Executando androiddeployqt...
cd "/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build" && \
        "/home/ivan/.config/env/qt/5.15.2/android/bin/androiddeployqt" \
                --input "android-wxapp-deployment-settings.json" \
                --output android \
                --android-platform "android-28" \
                --install
Generating Android Package
  Input file: android-wxapp-deployment-settings.json
  Output directory: /workspace/kiko/wx-qt-anrdoid-arm64-v8a/build/android/
  Application binary: wxapp
  Android build platform: android-28
  Install to device: Default device
Skipping createRCC
> Task :preBuild UP-TO-DATE
> Task :preDebugBuild UP-TO-DATE
> Task :compileDebugAidl
> Task :compileDebugRenderscript NO-SOURCE
> Task :generateDebugBuildConfig
> Task :mainApkListPersistenceDebug
> Task :generateDebugResValues
> Task :generateDebugResources
> Task :createDebugCompatibleScreenManifests
> Task :javaPreCompileDebug
> Task :extractDeepLinksDebug
> Task :processDebugManifest
> Task :mergeDebugShaders
> Task :compileDebugShaders
> Task :generateDebugAssets
> Task :mergeDebugAssets
> Task :processDebugJavaRes NO-SOURCE
> Task :mergeDebugResources
> Task :processDebugResources

> Task :compileDebugJavaWithJavac

> Task :compileDebugSources
> Task :checkDebugDuplicateClasses
> Task :dexBuilderDebug
> Task :mergeDebugJavaResource
> Task :mergeDebugJniLibFolders
> Task :mergeLibDexDebug
> Task :mergeProjectDexDebug
> Task :validateSigningDebug
> Task :mergeDebugNativeLibs
> Task :stripDebugDebugSymbols
> Task :desugarDebugFileDependencies
> Task :mergeExtDexDebug
> Task :packageDebug
> Task :assembleDebug

BUILD SUCCESSFUL in 5s
26 actionable tasks: 26 executed
Note: Some input files use or override a deprecated API.
Note: Recompile with -Xlint:deprecation for details.
Warning: Uninstall failed!
  -- Run with --verbose for more information.
^Cmake: *** [Makefile:107: apk] Interrupção

```

