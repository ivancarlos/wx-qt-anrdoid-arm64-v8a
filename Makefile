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

# Ferramentas auxiliares
AAPT       := $(ANDROID_SDK_ROOT)/build-tools/$(VERSION)/aapt
NDKDEPENDS := $(ANDROID_NDK_ROOT)/build/tools/ndk-depends
CMAKE_BIN  := $(ANDROID_SDK_ROOT)/cmake/3.22.1/bin/cmake
# CMAKE_BIN  := /home/ivan/.pyenv/shims/cmake
READELF    := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# ----------- VERBOSE -------------------

VERBOSE          ?= -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
                    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

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
BUILD_DIR      := $(PROJECT_ROOT)/build_android
ANDROID_LIB_DIR:= $(BUILD_DIR)/android/libs/$(QT_ARCH)
DEPLOY_JSON    := android-$(APP_NAME)-deployment-settings.json
# Nome alinhado com lib gerada pelo Qt: libwxapp_arm64-v8a.so
#DEPLOY_JSON    := android-lib$(APP_NAME)_arm64-v8a.so-deployment-settings.json
# ou seja: android-libwxapp_arm64-v8a.so-deployment-settings.json

# ============================================================
# APKs
# ============================================================
apk_debug       := $(BUILD_DIR)/android/build/outputs/apk/debug/android-debug.apk
apk_release     := $(BUILD_DIR)/android/build/outputs/apk/release/android-release.apk
APK             := $(apk_debug)

PACKAGE         := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/package: name='([^']+).*/\1/p")
ACTIVITYNAME    := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")


.PHONY: configure apk env build

all: apk

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
build:
	@echo "==> Compilando projeto Qt..."
	cd "$(BUILD_DIR)" && $(MAKE)
	@echo "[OK] Build Qt concluído."


# ============================================================
# DEPENDÊNCIAS — recursivas via readelf
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
		[ $$FOUND -eq 0 ] && echo "  ⚠️ $$LIB não encontrado em nenhum diretório conhecido"; \
	done; \
	echo "$$CHECKED" | tr ' ' '\n' | grep -v '^$$' | sort -u > "$(BUILD_DIR)/all-deps.txt"; \
	echo ""; \
	echo "📄 Lista final de dependências em $(BUILD_DIR)/all-deps.txt"

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

.PHONY: copy-deps-check
copy-deps-check:
	@echo " 🟨($@)🟨🟨🟨🟨🟨🟨🟨🟨🟨"
	@echo "📱 Copiando bibliotecas para APK..."
	@copy_with_check() { \
		src="$$1"; \
		dest="$$2"; \
		filename=$$(basename "$$src"); \
		if [ -f "$$dest/$$filename" ]; then \
			echo "⚠️  $$filename já existe em $$dest"; \
		else \
			cp -v "$$src" "$$dest"; \
			echo "✅ $$filename copiado para $$dest"; \
		fi; \
	}; \
	copy_with_check "$(BUILD_DIR)/libwxapp_arm64-v8a.so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	#copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_baseu-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	#copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_core-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_baseu_net-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_baseu_xml-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_adv-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_aui-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_html-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_media-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_propgrid-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_qa-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_ribbon-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_richtext-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_stc-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib/libwx_qtu_xrc-3.2-Android_$(QT_ARCH).so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/libz.so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/libc.so" "$(BUILD_DIR)/android/libs/arm64-v8a";  \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/libdl.so" "$(BUILD_DIR)/android/libs/arm64-v8a";  \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/libGLESv2.so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/liblog.so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
	copy_with_check "$(TOOLCHAIN_LIB_TOOLS)/usr/lib/libm.so" "$(BUILD_DIR)/android/libs/arm64-v8a"
# ============================================================
# APK
# ============================================================

.PHONY: apk apk-readelf build find-deps-readelf
# deploy: jni-build configure build find-deps-readelf copy-deps copy-deps-check apk
deploy: configure build apk
apk:
	make -C$(BUILD_DIR) $@
	@echo "[OK] APK gerado."

apk-local:
	@echo "==> Rodando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
	"$(ANDROIDDEPLOYQT)" \
		--input "$(DEPLOY_JSON)" \
		--output android \
		--android-platform "$(ANDROID_NDK_PLATFORM)"
	@echo "[OK] APK gerado."


# ============================================================
# 1) Build JNI .so com CMake + NDK
# ============================================================
.PHONY: jni-build
jni-build:
	rm -rf "$(BUILD_DIR)"
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && \
		"$(CMAKE_BIN)" \
		    $(VERBOSE) \
			-DANDROID_ABI="$(QT_ARCH)" \
			-DANDROID_PLATFORM="$(CONF_ANDROID_LEVEL)" \
			-DANDROID_NDK="$(ANDROID_NDK_ROOT)" \
			-DCMAKE_TOOLCHAIN_FILE="$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake" \
			-DWX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			"$(PROJECT_ROOT)/android/cpp"
	cd "$(BUILD_DIR)" && "$(CMAKE_BIN)" --build .

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
