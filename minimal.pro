# ============================================
# Projeto Qt "casca" para empacotar o app Android
# usando androiddeployqt. A lógica nativa real
# (wxWidgets + JNI) é construída via CMake/jni-build.
# ============================================

#QT += core gui widgets androidextras
QT += core gui widgets
CONFIG += c++11

TEMPLATE = app
TARGET   = wxapp

# Compilar só para arm64-v8a (ajuste se precisar de mais ABIs)
ANDROID_ABIS = arm64-v8a

# ------------------------------------------------------------
# Fontes Qt
# ------------------------------------------------------------
# Aqui você pode colocar um stub Qt qualquer, se quiser,
# mas para o empacotamento o Qt não precisa ter lógica própria.
# Se tiver algum arquivo fonte de Qt, liste aqui, por exemplo:
#
#   SOURCES += $$_PRO_FILE_PWD_/qt_stub.cpp
#
# Por enquanto, deixamos vazio:
#SOURCES +=
SOURCES += $$_PRO_FILE_PWD_/qt_stub.cpp

# ------------------------------------------------------------
# Diretório do pacote Android (Manifest, Java, etc.)
# ------------------------------------------------------------
# IMPORTANTE: usar SEMPRE $$_PRO_FILE_PWD_ aqui, pois o qmake
# roda dentro de build_android (shadow build). Assim, o Qt
# encontra o AndroidManifest.xml em:
#
#   $$_PRO_FILE_PWD_/android/AndroidManifest.xml
#
#ANDROID_PACKAGE_SOURCE_DIR = $$_PRO_FILE_PWD_/android
#ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android/java
ANDROID_PACKAGE_SOURCE_DIR = $$_PRO_FILE_PWD_/android

# ------------------------------------------------------------
# Bibliotecas nativas extras
# ------------------------------------------------------------
# As libs nativas (libwxapp.so, libs do wx, libc++_shared, etc.)
# serão copiadas pelo seu Makefile (targets find-deps-readelf /
# copy-deps) para o lugar que o androiddeployqt espera.
#
# Portanto, NÃO precisamos usar ANDROID_EXTRA_LIBS aqui.
#
# Se no futuro você quiser apontar para uma lib externa ao
# diretório android/, poderia fazer algo como:
#
# ANDROID_EXTRA_LIBS = \
#     $$_PRO_FILE_PWD_/build_android/libwxapp.so
#
# Mas, com o fluxo atual (Makefile que copia para android/libs),
# isso é desnecessário e só complica.
