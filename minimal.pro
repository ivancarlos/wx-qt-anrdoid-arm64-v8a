# ============================================
# wxWidgets + Qt + Android (arm64-v8a)
# Gera libwxapp_arm64-v8a.so para androiddeployqt
# ============================================

QT       += core gui widgets androidextras
TEMPLATE = lib
TARGET   = wxapp

CONFIG  += c++17 warn_on exceptions

DEFINES += __WXQT__

# ===== ABI usada no Android =====
ANDROID_ABIS = arm64-v8a

# ===== Ajusta para seu Makefile =====
QT_ARCH = $$QT_ARCH
isEmpty(QT_ARCH) {
    QT_ARCH = arm64-v8a
}

# ===== wxWidgets sysroot raiz =====
isEmpty(WX_ANDROID_ROOT) {
    WX_ANDROID_ROOT = $$HOME/wx/android-wx-3.2.4
}
message("WX_ANDROID_ROOT = $$WX_ANDROID_ROOT")
message("QT_ARCH = $$QT_ARCH")

# ============================================
# Build Desktop (Linux) — wxWidgets nativo
# ============================================
!android {
    message("== Build Desktop (Linux) ==")

    WX_CONFIG = wx-config
    WX_CFLAGS = $$system("$${WX_CONFIG} --cflags")
    WX_LIBS   = $$system("$${WX_CONFIG} --libs std,qt")

    QMAKE_CXXFLAGS += $$WX_CFLAGS
    LIBS += $$WX_LIBS
}

# ============================================
# Build Android (NDK)
# ============================================
android {
    message("== Build Android / NDK ==")

    ANDROID_ARCH = $$QT_ARCH
    SYSROOT      = $${WX_ANDROID_ROOT}/$${ANDROID_ARCH}/usr

    message("SYSROOT = $$SYSROOT")

    # wx-config dentro do sysroot Android
    WX_CONFIG = "$${SYSROOT}/bin/wx-config"
    WX_CFLAGS = $$system("$${WX_CONFIG} --cflags")

    message("WX_CONFIG = $$WX_CONFIG")
    message("WX_CFLAGS = $$WX_CFLAGS")

    # Inclui includes do wxWidgets
    INCLUDEPATH += $$SYSROOT/include
    QMAKE_CXXFLAGS += $$WX_CFLAGS

    # Diretório das libs wxWidgets
    WX_LIB_DIR = $${SYSROOT}/lib
    message("WX_LIB_DIR = $$WX_LIB_DIR")

    # Link explícito das libs principais wx (igual seu projeto antigo)
    LIBS += \
        $${WX_LIB_DIR}/libwx_qtu_core-3.2-Android_$${QT_ARCH}.so \
        $${WX_LIB_DIR}/libwx_baseu-3.2-Android_$${QT_ARCH}.so

    # Bibliotecas padrão Android
    LIBS += -llog -lz -lc++_shared
}

# ============================================
# Fontes do projeto
# ============================================

SOURCES += \
    dialogs.cpp

HEADERS += \
    dialogs.h

# ============================================
# Android packaging
# ============================================
ANDROID_PACKAGE_SOURCE_DIR = android

