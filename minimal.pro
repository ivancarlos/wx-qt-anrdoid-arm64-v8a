QT       += core gui widgets opengl
CONFIG   += c++11

TEMPLATE  = app
TARGET    = CubeGL
ANDROID_ABIS = arm64-v8a

SOURCES  += main.cpp glwidget.cpp
HEADERS  += glwidget.h

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
QMAKE_CXXFLAGS_RELEASE += -O2
