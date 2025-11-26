✅ Modo RELEASE (Compilação Bem-Sucedida)
Quando o framework está configurado para o modo RELEASE, a compilação e o link do projeto são concluídos com sucesso.

Log de Exemplo (Sucesso):

```{bash}
==> Compilando projeto (arm64-v8a)...
cd "/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build" && make
[...]
/home/ivan/Android/Sdk/ndk/android-ndk-r21e/toolchains/llvm/prebuilt/linux-x86_64/bin/clang++ -target aarch64-linux-android28 -fno-limit-debug-info -Wl,-soname,libwxapp_arm64-v8a.so [...] -shared -o libwxapp_arm64-v8a.so arm64-v8a/dialogs.o    -llog /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib/libwx_qtu_core-3.2-Android_arm64-v8a.so [...] -lGLESv2    -llog -lz -lm -ldl -lc
make[1]: Saindo do diretório '/workspace/kiko/wx-qt-anrdoid-arm64-v8a/build'
[OK] Build concluído.
```

🐞 Modo DEBUG (Falha de Linker)
No modo DEBUG, o processo de compilação falha na etapa de linkagem (linker), resultando em erros de referências não definidas (undefined reference).

O linker não está encontrando os símbolos relacionados à asserção e debugging do wxWidgets, como wxTheAssertHandler e wxOnAssert.

Log de Exemplo (Falha):

```{bash}
dialogs.cpp:(.text._ZN20wxTopLevelWindowBase21ShowWithoutActivatingEv[_ZN20wxTopLevelWindowBase21ShowWithoutActivatingEv]+0xc): undefined reference to `wxTheAssertHandler'
dialogs.cpp:(.text._ZN20wxTopLevelWindowBase21ShowWithoutActivatingEv[_ZN20wxTopLevelWindowBase21ShowWithoutActivatingEv]+0x3c): undefined reference to `wxOnAssert(char const*, int, char const*, char const*, char const*)'
[...]
clang++: error: linker command failed with exit code 1 (use -v to see invocation)
make[1]: *** [Makefile:235: libwxapp_arm64-v8a.so] Erro 1
make: *** [Makefile:98: build] Erro 2
```
Diagnóstico: As bibliotecas do wxWidgets que contêm as rotinas de assert e handler de debug (geralmente uma versão da libwx_baseu ou libwx_qtu_core compilada com flags de debug) não estão sendo incluídas ou estão sendo referenciadas incorretamente no comando de linkagem quando o modo DEBUG está ativo.



```{bash}
$ make
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

```

