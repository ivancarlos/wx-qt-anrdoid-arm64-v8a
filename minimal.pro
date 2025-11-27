# ============================================
# Projeto Qt para Android com interface visual
# ============================================

QT += core gui widgets
CONFIG += c++11

TEMPLATE = app
TARGET = wxapp

ANDROID_ABIS = arm64-v8a

# Fonte principal com interface Qt
SOURCES += $$_PRO_FILE_PWD_/qt_stub.cpp

# Diretório do pacote Android
ANDROID_PACKAGE_SOURCE_DIR = $$_PRO_FILE_PWD_/android

# Definições para Android
DEFINES += QT_DEPRECATED_WARNINGS

# Otimizações
android {
    # Garante que a app seja otimizada
    QMAKE_CXXFLAGS_RELEASE += -O2
}
