QT += core gui widgets

TARGET = wxapp
TEMPLATE = app

ANDROID_ABIS = arm64-v8a

# Ativa integração JNI
ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android/java

# Garante que o Qt carregue sua lib
ANDROID_EXTRA_LIBS = \
    $$PWD/build_android/libwxapp_arm64-v8a.so

