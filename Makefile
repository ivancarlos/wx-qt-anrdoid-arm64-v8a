# ============================================================
# Makefile para compilar wxapp com CMake+NDK e empacotar com Qt
# usando análise de dependências via readelf
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

PROJECT_ROOT := $(CURDIR)
BUILD_DIR    := $(PROJECT_ROOT)/build_android

# JSON que o qmake gera e o androiddeployqt consome
DEPLOY_JSON  := android-$(APP_NAME)-deployment-settings.json

# Onde o androiddeployqt espera as libs dentro do build_dir:
ANDROID_LIB_DIR := $(BUILD_DIR)/android/libs/$(QT_ARCH)

# wxWidgets Android já instalado
WX_ANDROID_ROOT := $(HOME)/wx/android-wx-3.2.4
WX_LIB_DIR      := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib

# Ambiente Android
export ANDROID_SDK_ROOT       := $(HOME)/Android/Sdk
export ANDROID_NDK_ROOT       := $(ANDROID_SDK_ROOT)/ndk/$(NDK_VERSION)
export ANDROID_TOOLCHAIN_PATH := $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_NDK_PLATFORM   := android-$(CONF_ANDROID_LEVEL)
export QT_ARCH                := $(QT_ARCH)
export WX_ANDROID_ROOT        := $(WX_ANDROID_ROOT)

# Ferramentas auxiliares
CMAKE_BIN   := $(ANDROID_SDK_ROOT)/cmake/3.22.1/bin/cmake
READELF     := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# libc++ do NDK
NDK_CPP_SYSROOT_DIR := $(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/lib$(CONF_COMPILER_ARCH)-linux-android
NDK_CPP_STL_DIR     := $(ANDROID_NDK_ROOT)/sources/cxx-stl/llvm-libc++/libs/$(QT_ARCH)

# Nome da lib que o CMake gera
LIB_NAME := lib$(APP_NAME).so

# ============================================================
# 1) Build JNI .so com CMake + NDK
# ============================================================
.PHONY: jni-build
jni-build:
	rm -rf "$(BUILD_DIR)"
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && \
		"$(CMAKE_BIN)" \
			-DANDROID_ABI="$(QT_ARCH)" \
			-DANDROID_PLATFORM="$(CONF_ANDROID_LEVEL)" \
			-DANDROID_NDK="$(ANDROID_NDK_ROOT)" \
			-DCMAKE_TOOLCHAIN_FILE="$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake" \
			-DWX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			"$(PROJECT_ROOT)/android/cpp"
	cd "$(BUILD_DIR)" && "$(CMAKE_BIN)" --build .

# ============================================================
# 2) Gera Makefile Qt + deployment JSON (não compila nada)
# ============================================================
.PHONY: configure
configure:
	cd "$(BUILD_DIR)" && "$(QMAKE)" -makefile ../minimal.pro

# Opcional: se quiser ainda rodar o make do Qt (normalmente não precisa)
.PHONY: build
build: configure
	@echo "==> Compilando projeto Qt (opcional)..."
	cd "$(BUILD_DIR)" && $(MAKE)
	@echo "[OK] Build Qt concluído."

# ============================================================
# 3) DEPENDÊNCIAS — recursivas via readelf
# ============================================================

.PHONY: find-deps-readelf copy-deps deps-main

# Gera lista de TODAS as libs (principal + dependências recursivas)
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

# Copia todas as libs da lista para android/libs/$(QT_ARCH)
copy-deps:
	@if [ ! -f "$(BUILD_DIR)/all-deps.txt" ]; then \
		echo "❌ Rode 'make find-deps-readelf' primeiro!"; \
		exit 1; \
	fi
	@echo "📦 Copiando dependências para $(ANDROID_LIB_DIR)..."
	@mkdir -p "$(ANDROID_LIB_DIR)"

	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		if [ "$$dep" = "$(LIB_NAME)" ]; then \
			echo "  → $$dep (principal)"; \
			cp -v "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/lib$(APP_NAME)_$(QT_ARCH).so"; \
			continue; \
		fi; \
		COPIED=0; \
		for P in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$P/$$dep" ]; then \
				echo "  → $$dep"; \
				cp -v "$$P/$$dep" "$(ANDROID_LIB_DIR)/"; \
				COPIED=1; \
				break; \
			fi; \
		done; \
		[ $$COPIED -eq 0 ] && echo "  ⚠️ $$dep não encontrado em WX/Qt/NDK"; \
	done < "$(BUILD_DIR)/all-deps.txt"

	@echo "📦 Forçando cópia de libc++_shared.so"
	@cp -v "$(NDK_CPP_STL_DIR)/libc++_shared.so" "$(ANDROID_LIB_DIR)/" || true

# ============================================================
# 4) Gera APK com androiddeployqt usando as libs copiadas
# ============================================================

.PHONY: apk-readelf apk

apk-readelf: jni-build configure find-deps-readelf copy-deps
	@echo "==> Rodando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)"
	@echo "[OK] APK gerado com dependências completas (readelf)."

apk: apk-readelf

# ============================================================
# Limpeza
# ============================================================
.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)" android/build *.json *.apk
