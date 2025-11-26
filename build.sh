#!/usr/bin/env bash
set -euo pipefail

QT_VERSION=5.15.2
QT5_CUSTOM_DIR="${HOME}/.config/env/qt/${QT_VERSION}/android"
QMAKE="${QT5_CUSTOM_DIR}/bin/qmake"

NDK_VERSION=android-ndk-r21e
CONF_ANDROID_LEVEL=28

QT_ARCH=arm64-v8a
WX_ANDROID_ROOT="${HOME}/wx/android-wx-3.2.4"

export ANDROID_SDK_ROOT="${HOME}/Android/Sdk"
export ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk/${NDK_VERSION}"
export ANDROID_TOOLCHAIN_PATH="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
export ANDROID_NDK_PLATFORM="android-${CONF_ANDROID_LEVEL}"

###############################################
# DEBUG
###############################################
echo "QT_VERSION      = ${QT_VERSION}"
echo "QT5_CUSTOM_DIR  = ${QT5_CUSTOM_DIR}"
echo "QMAKE           = ${QMAKE}"
echo "QT_ARCH         = ${QT_ARCH}"
echo "WX_ANDROID_ROOT = ${WX_ANDROID_ROOT}"

mkdir -p build
cd build

# Gera Makefile com o kit Android
"$QMAKE" -makefile ../minimal.pro \
    WX_ANDROID_ROOT="${WX_ANDROID_ROOT}" \
    QT_ARCH="${QT_ARCH}"

echo "[INFO] Makefile gerado em $(pwd)"

# Se quiser já compilar aqui:
make

echo "[INFO] Build concluído."
