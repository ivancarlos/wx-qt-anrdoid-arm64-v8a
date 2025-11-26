# ============================================================
# Makefile Android + Qt + wxWidgets + JNI (wxapp)
# Gera:
#   - libwxapp.so usando clang/NDK (JNI + inicialização wx)
#   - Makefile via qmake
#   - dependências completas via readelf
#   - APK com androiddeployqt
# ============================================================

APP_NAME        := wxapp
LIB_NAME        := libwxapp.so

# ============================================================
# Qt
# ============================================================
QT_VERSION      ?= 5.15.2
QT_ANDROID_DIR  := $(HOME)/.config/env/qt/$(QT_VERSION)/android
QMAKE           := $(QT_ANDROID_DIR)/bin/qmake
ANDROIDDEPLOYQT := $(QT_ANDROID_DIR)/bin/androiddeployqt

# ============================================================
# Android / NDK
# ============================================================
NDK_VERSION        ?= android-ndk-r21e
CONF_ANDROID_LEVEL ?= 28
QT_ARCH            ?= arm64-v8a
CONF_COMPILER_ARCH := aarch64

export ANDROID_SDK_ROOT      := $(HOME)/Android/Sdk
export ANDROID_NDK_ROOT      := $(ANDROID_SDK_ROOT)/ndk/$(NDK_VERSION)
export ANDROID_TOOLCHAIN_PATH:= $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_NDK_PLATFORM  := android-$(CONF_ANDROID_LEVEL)

VERSION ?= 36.1.0

AAPT            := $(ANDROID_SDK_ROOT)/build-tools/$(VERSION)/aapt
NDKDEPENDS      := $(ANDROID_NDK_ROOT)/build/tools/ndk-depends
READELF         := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# ============================================================
# Caminhos wxWidgets
# ============================================================
WX_ANDROID_ROOT ?= $(HOME)/wx/android-wx-3.2.4
WX_LIB_DIR      := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib

NDK_CPP_SYSROOT_DIR := $(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/lib$(CONF_COMPILER_ARCH)-linux-android
NDK_CPP_STL_DIR     := $(ANDROID_NDK_ROOT)/sources/cxx-stl/llvm-libc++/libs/$(QT_ARCH)

# ============================================================
# Diretórios do projeto
# ============================================================
PROJECT_ROOT   := $(CURDIR)
BUILD_DIR      := $(PROJECT_ROOT)/build
ANDROID_LIB_DIR:= $(BUILD_DIR)/android/libs/$(QT_ARCH)
DEPLOY_JSON    := android-$(APP_NAME)-deployment-settings.json

# ============================================================
# APKs
# ============================================================
apk_debug       := build/android/build/outputs/apk/debug/android-debug.apk
apk_release     := build/android/build/outputs/apk/release/android-release.apk
APK             := $(apk_debug)

PACKAGE         := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/package: name='([^']+).*/\1/p")
ACTIVITYNAME    := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")

# ============================================================
# JNI / wxWidgets entry libwxapp.so
# ============================================================
JNI_SRC := \
    android/cpp/wx_jni.cpp \
    android/cpp/myapp_wx.cpp

JNI_INCLUDES := \
    -I$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/include \
    -I$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib \
    -I$(ANDROID_NDK_ROOT)/sources/android/native_app_glue \
    -I$(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/include

JNI_LDFLAGS := \
    -L$(WX_LIB_DIR) \
    -lwx_qtu_core-3.2-Android_$(QT_ARCH) \
    -lwx_baseu-3.2-Android_$(QT_ARCH) \
    -landroid -llog

# ============================================================
# TARGETS PRINCIPAIS
# ============================================================

.PHONY: all build configure apk jni-build env info clean

all: apk

# ------------------------------------------------------------
# Compila a lib JNI (libwxapp.so)
# ------------------------------------------------------------
jni-build:
	@echo "==> Compilando libwxapp.so (JNI + wxWidgets)..."
	mkdir -p "$(BUILD_DIR)"
	$(ANDROID_TOOLCHAIN_PATH)/bin/$(CONF_COMPILER_ARCH)-linux-android$(CONF_ANDROID_LEVEL)-clang++ \
		-shared -fPIC \
		-o "$(BUILD_DIR)/$(LIB_NAME)" \
		$(JNI_SRC) \
		$(JNI_INCLUDES) \
		$(JNI_LDFLAGS)
	@echo "[OK] libwxapp.so gerada."

# ------------------------------------------------------------
# Gera Makefile via qmake
# ------------------------------------------------------------
configure: env
	@echo "==> Rodando qmake..."
	@mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && \
		"$(QMAKE)" -makefile ../minimal.pro \
			WX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			QT_ARCH="$(QT_ARCH)"
	@echo "[OK] Makefile gerado."

# ------------------------------------------------------------
# Compila projeto Qt + wxWidgets
# ------------------------------------------------------------
build: configure
	@echo "==> Compilando projeto Qt..."
	cd "$(BUILD_DIR)" && $(MAKE)
	@echo "[OK] Build Qt concluído."

# ============================================================
# DEPENDÊNCIAS — recursivas via readelf
# ============================================================

.PHONY: find-deps-readelf copy-deps deps-main

find-deps-readelf:
	@echo "🔍 Lendo dependências com readelf..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@cp "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/" 2>/dev/null || true
	@ALL_LIBS="$(LIB_NAME)"; \
	CHECKED=""; \
	while [ -n "$$ALL_LIBS" ]; do \
		LIB=$$(echo "$$ALL_LIBS" | awk '{print $$1}'); \
		ALL_LIBS=$$(echo "$$ALL_LIBS" | sed "s/^$$LIB *//"); \
		echo "$$CHECKED" | grep -qw "$$LIB" && continue; \
		CHECKED="$$CHECKED $$LIB"; \
		FOUND=0; \
		for P in "$(ANDROID_LIB_DIR)" "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$P/$$LIB" ]; then \
				echo "  📦 $$LIB em $$P"; \
				DEPS=$$($(READELF) -d "$$P/$$LIB" | grep NEEDED | awk '{print $$5}' | tr -d '[]'); \
				ALL_LIBS="$$ALL_LIBS $$DEPS"; \
				FOUND=1; \
				break; \
			fi; \
		done; \
		[ $$FOUND -eq 0 ] && echo "  ⚠️ $$LIB não encontrado em nenhum diretório"; \
	done; \
	echo "$$CHECKED" | tr ' ' '\n' | grep -v '^$$' | sort -u > "$(BUILD_DIR)/all-deps.txt"

# ------------------------------------------------------------
# Copia todas dependências reais
# ------------------------------------------------------------
copy-deps:
	@if [ ! -f "$(BUILD_DIR)/all-deps.txt" ]; then \
		echo "❌ Rode make find-deps-readelf primeiro!"; exit 1; fi
	@echo "📦 Copiando dependências..."
	mkdir -p "$(ANDROID_LIB_DIR)"
	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		for P in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$P/$$dep" ]; then \
				echo "  → $$dep"; \
				cp -v "$$P/$$dep" "$(ANDROID_LIB_DIR)/"; \
				break; \
			fi; \
		done; \
	done < "$(BUILD_DIR)/all-deps.txt"

	@echo "📦 Copiando libwxapp.so"
	cp -v "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/"

	@echo "📦 Copiando libc++_shared.so"
	cp -v "$(NDK_CPP_STL_DIR)/libc++_shared.so" "$(ANDROID_LIB_DIR)/"

# ============================================================
# APK
# ============================================================

apk-readelf: jni-build build find-deps-readelf copy-deps
	@echo "==> Rodando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)"
	@echo "[OK] APK gerado."

apk: apk-readelf

# ============================================================
# UTILITÁRIOS
# ============================================================

install:
	adb install -r "$(APK)"

run: install
	adb shell am start -n "$(PACKAGE)/$(ACTIVITYNAME)"

kill:
	adb shell am force-stop "$(PACKAGE)"

delete-data:
	adb shell pm clear "$(PACKAGE)"

uninstall:
	adb uninstall "$(PACKAGE)"

logcat:
	adb logcat | grep --line-buffered "$(PACKAGE)"

log3:
	adb logcat *:E DEBUG:* | grep -E "Fatal|SIG|JNI|$(PACKAGE)"

abi:
	adb shell getprop ro.product.cpu.abi

sdk:
	adb shell getprop ro.build.version.sdk

clean:
	rm -rf "$(BUILD_DIR)"

env:
	@echo "QT_ANDROID_DIR = $(QT_ANDROID_DIR)"
	@echo "ANDROID_NDK_ROOT = $(ANDROID_NDK_ROOT)"
	@echo "WX_ANDROID_ROOT = $(WX_ANDROID_ROOT)"

info:
	@echo "APK = $(APK)"
	@echo "PACKAGE = $(PACKAGE)"
	@echo "ACTIVITYNAME = $(ACTIVITYNAME)"

# EOF
