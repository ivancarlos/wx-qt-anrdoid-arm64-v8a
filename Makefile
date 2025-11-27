# ============================================================
# Makefile Android + Qt + wxWidgets + JNI (CubeGL)
# ============================================================
# Gera:
#   - libCubeGL_arm64-v8a.so via Qt/qmake (interface visual)
#   - libCubeGL.so via CMake/NDK (JNI + wxWidgets, opcional)
#   - APK com androiddeployqt
# ============================================================

APP_NAME := CubeGL
LIB_NAME := libCubeGL.so

# ============================================================
# CONFIGURAÇÕES Qt
# ============================================================
QT_VERSION      ?= 5.15.2
QT_ANDROID_DIR  := $(HOME)/.config/env/qt/$(QT_VERSION)/android
QMAKE           := $(QT_ANDROID_DIR)/bin/qmake
ANDROIDDEPLOYQT := $(QT_ANDROID_DIR)/bin/androiddeployqt

# ============================================================
# CONFIGURAÇÕES Android / NDK
# ============================================================
NDK_VERSION        ?= android-ndk-r21e
CONF_ANDROID_LEVEL ?= 28
QT_ARCH            ?= arm64-v8a
CONF_COMPILER_ARCH := aarch64

export ANDROID_SDK_ROOT       := $(HOME)/Android/Sdk
export ANDROID_NDK_ROOT       := $(ANDROID_SDK_ROOT)/ndk/$(NDK_VERSION)
export ANDROID_TOOLCHAIN_PATH := $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_NDK_PLATFORM   := android-$(CONF_ANDROID_LEVEL)

VERSION ?= 36.1.0

# Ferramentas auxiliares
AAPT    := $(ANDROID_SDK_ROOT)/build-tools/$(VERSION)/aapt
CMAKE   := $(ANDROID_SDK_ROOT)/cmake/3.22.1/bin/cmake
READELF := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# Flags verbose para CMake (debug)
VERBOSE ?= -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
           -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# ============================================================
# CONFIGURAÇÕES wxWidgets
# ============================================================
WX_ANDROID_ROOT     ?= $(HOME)/wx/android-wx-3.2.4
WX_LIB_DIR          := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib
NDK_CPP_SYSROOT_DIR := $(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/lib$(CONF_COMPILER_ARCH)-linux-android
NDK_CPP_STL_DIR     := $(ANDROID_NDK_ROOT)/sources/cxx-stl/llvm-libc++/libs/$(QT_ARCH)

# ============================================================
# DIRETÓRIOS DO PROJETO
# ============================================================
PROJECT_ROOT    := $(CURDIR)
BUILD_DIR       := $(PROJECT_ROOT)/build_android
JNI_BUILD_DIR   := $(BUILD_DIR)/jni_build
JNI_SRC_DIR     := $(PROJECT_ROOT)/android/cpp
ANDROID_LIB_DIR := $(BUILD_DIR)/android/libs/$(QT_ARCH)
DEPLOY_JSON     := android-$(APP_NAME)-deployment-settings.json

# ============================================================
# APK
# ============================================================
APK_DEBUG   := $(BUILD_DIR)/android/build/outputs/apk/debug/android-debug.apk
APK_RELEASE := $(BUILD_DIR)/android/build/outputs/apk/release/android-release.apk
APK         := $(APK_DEBUG)

PACKAGE      := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/package: name='([^']+).*/\1/p")
ACTIVITYNAME := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")

# ============================================================
# TARGETS PRINCIPAIS
# ============================================================
.PHONY: all configure build apk deploy clean

all: apk

# Workflow completo: Qt + dependências + APK
deploy: configure build find-deps-readelf copy-deps apk

# ============================================================
# 1. CONFIGURAÇÃO (qmake)
# ============================================================
.PHONY: configure env

configure: env
	@echo "==> Rodando qmake..."
	@mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && \
		"$(QMAKE)" -makefile ../minimal.pro \
			"CONFIG+=release" ANDROID_ABIS=arm64-v8a	\
			WX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			QT_ARCH="$(QT_ARCH)"
	@if [ -f "$(BUILD_DIR)/$(DEPLOY_JSON)" ]; then \
		sed -i 's|android-build|android|g' "$(BUILD_DIR)/$(DEPLOY_JSON)"; \
		echo "✓ JSON deployment corrigido"; \
	fi
	@echo "[OK] Makefile gerado."

env:
	@echo "QT_ANDROID_DIR   = $(QT_ANDROID_DIR)"
	@echo "ANDROID_NDK_ROOT = $(ANDROID_NDK_ROOT)"
	@echo "WX_ANDROID_ROOT  = $(WX_ANDROID_ROOT)"

# ============================================================
# 2. COMPILAÇÃO Qt (interface visual)
# ============================================================
.PHONY: build copy-qt-lib

build: configure
	@echo "==> Compilando projeto Qt..."
	$(MAKE) -C "$(BUILD_DIR)"
	@echo "[OK] Build Qt concluído."
	@$(MAKE) copy-qt-lib

copy-qt-lib:
	@echo "==> Copiando libCubeGL_arm64-v8a.so para android/libs..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@cp -f "$(BUILD_DIR)/libCubeGL_arm64-v8a.so" \
	       "$(ANDROID_LIB_DIR)/libCubeGL_arm64-v8a.so"
	@echo "[OK] Biblioteca Qt copiada."

# ============================================================
# 3. COMPILAÇÃO JNI (wxWidgets + CMake) - OPCIONAL
# ============================================================
.PHONY: jni-build jni-clean

jni-build: jni-clean
	@echo "==> Compilando biblioteca JNI (wxWidgets)..."
	@mkdir -p "$(JNI_BUILD_DIR)"
	cd "$(JNI_BUILD_DIR)" && \
		"$(CMAKE)" \
			$(VERBOSE) \
			-DCMAKE_TOOLCHAIN_FILE="$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake" \
			-DANDROID_ABI="$(QT_ARCH)" \
			-DANDROID_PLATFORM="$(CONF_ANDROID_LEVEL)" \
			-DANDROID_NDK="$(ANDROID_NDK_ROOT)" \
			-DWX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			"$(JNI_SRC_DIR)" && \
		"$(CMAKE)" --build .
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@if [ -f "$(JNI_BUILD_DIR)/libCubeGL.so" ]; then \
		cp -f "$(JNI_BUILD_DIR)/libCubeGL.so" "$(ANDROID_LIB_DIR)/"; \
		echo "[OK] libCubeGL.so (JNI) copiado."; \
	fi

jni-clean:
	@rm -rf "$(JNI_BUILD_DIR)"

# ============================================================
# 4. DEPENDÊNCIAS (readelf recursivo)
# ============================================================
.PHONY: find-deps-readelf copy-deps

find-deps-readelf:
	@echo "🔍 Lendo dependências com readelf..."; \
	ALL_LIBS="$(LIB_NAME)"; \
	CHECKED=""; \
	while [ -n "$$ALL_LIBS" ]; do \
		set -- $$ALL_LIBS; \
		LIB="$$1"; \
		shift; \
		ALL_LIBS="$$*"; \
		echo "$$CHECKED" | grep -qw "$$LIB" && continue; \
		CHECKED="$$CHECKED $$LIB"; \
		FOUND=0; \
		for P in "$(BUILD_DIR)" "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$P/$$LIB" ]; then \
				echo "  📦 $$LIB em $$P"; \
				DEPS=$$("$(READELF)" -d "$$P/$$LIB" 2>/dev/null | grep NEEDED | awk '{print $$5}' | tr -d '[]'); \
				ALL_LIBS="$$ALL_LIBS $$DEPS"; \
				FOUND=1; \
				break; \
			fi; \
		done; \
		[ $$FOUND -eq 0 ] && echo "  ⚠️  $$LIB não encontrado"; \
	done; \
	echo "$$CHECKED" | tr ' ' '\n' | grep -v '^$$' | sort -u > "$(BUILD_DIR)/all-deps.txt"; \
	echo ""; \
	echo "📄 Lista final: $(BUILD_DIR)/all-deps.txt"

copy-deps:
	@if [ ! -f "$(BUILD_DIR)/all-deps.txt" ]; then \
		echo "❌ Execute 'make find-deps-readelf' primeiro!"; exit 1; \
	fi
	@echo "📦 Copiando dependências para $(ANDROID_LIB_DIR)..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		for P in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$P/$$dep" ]; then \
				echo "  → $$dep"; \
				cp -f "$$P/$$dep" "$(ANDROID_LIB_DIR)/"; \
				break; \
			fi; \
		done; \
	done < "$(BUILD_DIR)/all-deps.txt"
	@if [ -f "$(BUILD_DIR)/$(LIB_NAME)" ]; then \
		echo "📦 Copiando $(LIB_NAME)"; \
		cp -f "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/"; \
	fi
	@echo "📦 Copiando libc++_shared.so"
	@cp -f "$(NDK_CPP_STL_DIR)/libc++_shared.so" "$(ANDROID_LIB_DIR)/"
	@echo "[OK] Dependências copiadas."

# ============================================================
# 5. GERAÇÃO DO APK
# ============================================================
.PHONY: apk apk-local

apk: configure build find-deps-readelf copy-deps
	@echo "==> Gerando APK com androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)" \
			--gradle
	@echo ""
	@echo "✅ [OK] APK gerado:"
	@echo "    $(APK_DEBUG)"
	@echo ""

# ============================================================
# 6. UTILITÁRIOS ADB
# ============================================================
.PHONY: install run kill delete-data uninstall logcat log3 abi sdk info

install:
	@echo "==> Instalando APK no dispositivo..."
	adb install -r "$(APK)"

run: install
	@echo "==> Iniciando aplicativo..."
	adb shell am start -n "$(PACKAGE)/$(ACTIVITYNAME)"

kill:
	@echo "==> Forçando parada do app..."
	adb shell am force-stop "$(PACKAGE)"

delete-data:
	@echo "==> Limpando dados do app..."
	adb shell pm clear "$(PACKAGE)"

uninstall:
	@echo "==> Desinstalando app..."
	adb uninstall "$(PACKAGE)"

unzip:
	@echo "==> verificar isso rapidamente $(LIB_NAME)..."
	unzip -l "$(APK)" | grep lib.*\.so

log:
	@echo "==> Logcat filtrado por $(PACKAGE)..."
	adb logcat | grep --line-buffered "$(PACKAGE)"
log2:
	@echo "==> Logcat apenas erros e crashes..."
	adb logcat -c              # limpa lixo anterior
	adb logcat Qt:V *:S        # mostra só Qt + stack

log3:
	@echo "==> Logcat apenas erros e crashes..."
	adb logcat *:E DEBUG:* | grep -E "Fatal|SIG|JNI|$(PACKAGE)"

abi:
	@echo "==> ABI do dispositivo:"
	@adb shell getprop ro.product.cpu.abi

sdk:
	@echo "==> SDK do dispositivo:"
	@adb shell getprop ro.build.version.sdk

info:
	@echo "APK          = $(APK)"
	@echo "PACKAGE      = $(PACKAGE)"
	@echo "ACTIVITYNAME = $(ACTIVITYNAME)"

# ============================================================
# 7. LIMPEZA
# ============================================================
.PHONY: clean clean-all

clean:
	@echo "==> Limpando build_android..."
	rm -rf "$(BUILD_DIR)"
	@echo "[OK] Diretório limpo."

clean-all: clean
	@echo "==> Limpeza completa (incluindo cache Gradle)..."
	rm -rf "$(PROJECT_ROOT)/.gradle"
	rm -rf "$(PROJECT_ROOT)/android/.gradle"
	@echo "[OK] Limpeza completa."

# EOF
