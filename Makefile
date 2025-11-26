# ============================================================
# Makefile para compilar wxapp com CMake+NDK e empacotar com Qt
# ============================================================

APP_NAME        := wxapp
QT_VERSION      := 5.15.2

QT_ANDROID_DIR  := $(HOME)/.config/env/qt/$(QT_VERSION)/android
QMAKE           := $(QT_ANDROID_DIR)/bin/qmake
ANDROIDDEPLOYQT := $(QT_ANDROID_DIR)/bin/androiddeployqt

NDK_VERSION        := android-ndk-r21e
CONF_ANDROID_LEVEL := 28
QT_ARCH            := arm64-v8a
CONF_COMPILER_ARCH := aarch64


PROJECT_ROOT     := $(CURDIR)
BUILD_DIR        := $(PROJECT_ROOT)/build_android
DEPLOY_JSON_NAME := android-$(APP_NAME)-deployment-settings.json

export ANDROID_SDK_ROOT       := $(HOME)/Android/Sdk
export ANDROID_NDK_ROOT       := $(ANDROID_SDK_ROOT)/ndk/$(NDK_VERSION)
export ANDROID_TOOLCHAIN_PATH := $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86_64
export QT_ARCH                := arm64-v8a
export WX_ANDROID_ROOT        := $(HOME)/wx/android-wx-3.2.4

# Executáveis
CMAKE_BIN   := $(ANDROID_SDK_ROOT)/cmake/3.22.1/bin/cmake
AAPT        := $(ANDROID_SDK_ROOT)/build-tools/36.1.0/aapt
READELF     := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

LIB_NAME := lib$(APP_NAME)_$(QT_ARCH).so

# ===================================
# 1) Build JNI .so com CMake + NDK
# ===================================
jni-build:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && \
		$(CMAKE_BIN) -DANDROID_ABI=$(QT_ARCH) \
		             -DANDROID_PLATFORM=$(CONF_ANDROID_LEVEL) \
		             -DANDROID_NDK=$(ANDROID_NDK_ROOT) \
		             -DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake \
		             -DWX_ANDROID_ROOT=$(WX_ANDROID_ROOT) \
		             $(PROJECT_ROOT)/android/cpp
	cd $(BUILD_DIR) && $(CMAKE_BIN) --build .

# ===================================
# 2) Gera Makefile Qt + deployment JSON
# ===================================
configure:
	cd $(BUILD_DIR) && $(QMAKE) -makefile ../minimal.pro

# ===================================
# 3) Gera APK com androiddeployqt
# ===================================
apk: jni-build configure
	cd $(BUILD_DIR) && \
		$(ANDROIDDEPLOYQT) \
			--input $(DEPLOY_JSON_NAME) \
			--output android \
			--android-platform android-$(CONF_ANDROID_LEVEL)

# ===================================
# Utilidades
# ===================================
clean:
	rm -rf $(BUILD_DIR) android/build *.json *.apk

