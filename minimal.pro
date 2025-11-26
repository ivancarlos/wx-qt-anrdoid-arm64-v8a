#-------------------------------------------------
# Projeto gsoc2014 - wxWidgets + Qt (Android)
#-------------------------------------------------

QT       += core gui widgets opengl svg testlib

TARGET   = wxapp
TEMPLATE = app

# <<< ADICIONE AQUI >>>
ANDROID_ABIS = arm64-v8a

SOURCES += dialogs.cpp
HEADERS += dialogs.h

CONFIG  += mobility
MOBILITY =

DEFINES += __WXQT__

# Para logcat no Android
LIBS += -llog

# Raiz padrão da instalação wxWidgets Android (3.2.4) para arm64-v8a
# Estrutura:
#   ~/wx/android-wx-3.2.4/
#       arm64-v8a/usr/bin/wx-config
#       arm64-v8a/usr/lib/...
isEmpty(WX_ANDROID_ROOT) {
    WX_ANDROID_ROOT = $$HOME/wx/android-wx-3.2.4
}

message("WX_ANDROID_ROOT = $$WX_ANDROID_ROOT")
message("QT_ARCH = $$QT_ARCH")

android {
    message("Compilando para Android (NDK)")

    ANDROID_ARCH = $$QT_ARCH          # deve ser "arm64-v8a"
    SYSROOT      = $${WX_ANDROID_ROOT}/$${ANDROID_ARCH}/usr

    message("SYSROOT = $$SYSROOT")

    # wx-config específico desse sysroot Android
    WX_CONFIG = "$${SYSROOT}/bin/wx-config"
    message("Usando WX_CONFIG = $$WX_CONFIG")

    # Pegamos APENAS os CFLAGS do wx (includes/defines)
    WX_CFLAGS = $$system("$${WX_CONFIG} --cflags")
    message("WX_CFLAGS = $$WX_CFLAGS")

    QMAKE_CXXFLAGS += $$WX_CFLAGS

    # Diretório das libs wx
    WX_LIB_DIR = $${SYSROOT}/lib
    message("WX_LIB_DIR = $$WX_LIB_DIR")

    # Linka explicitamente só as libs que existem (arm64-v8a)
    LIBS += \
        $${WX_LIB_DIR}/libwx_qtu_core-3.2-Android_$${QT_ARCH}.so \
        $${WX_LIB_DIR}/libwx_baseu-3.2-Android_$${QT_ARCH}.so

} else {
    message("Compilando fora do Android (desktop)")

    WX_CONFIG = wx-config

    WX_CFLAGS = $$system("$${WX_CONFIG} --cflags")
    WX_LIBS   = $$system("$${WX_CONFIG} --libs std,qt")

    message("WX_CFLAGS (desktop) = $$WX_CFLAGS")
    message("WX_LIBS   (desktop) = $$WX_LIBS")

    QMAKE_CXXFLAGS += $$WX_CFLAGS
    LIBS           += $$WX_LIBS
}

