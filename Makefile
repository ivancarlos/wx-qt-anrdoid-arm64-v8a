# ============================================================
# Makefile simples para:
#  - gerar Makefile Android com qmake
#  - compilar libgsoc2014_arm64-v8a.so
#  - rodar androiddeployqt para gerar/instalar APK
# ============================================================

# ---------- Configurações gerais ----------
APP_NAME        := wxapp

QT_VERSION      ?= 5.15.2
QT_ANDROID_DIR  := $(HOME)/.config/env/qt/$(QT_VERSION)/android
QMAKE           := $(QT_ANDROID_DIR)/bin/qmake
ANDROIDDEPLOYQT := $(QT_ANDROID_DIR)/bin/androiddeployqt

NDK_VERSION         ?= android-ndk-r21e
CONF_ANDROID_LEVEL  ?= 28
QT_ARCH             ?= arm64-v8a
WX_ANDROID_ROOT     ?= $(HOME)/wx/android-wx-3.2.4

DEPLOY_JSON    := android-$(APP_NAME)-deployment-settings.json

PROJECT_ROOT   := $(CURDIR)
BUILD_DIR      := $(PROJECT_ROOT)/build

# Nome da lib gerada pelo build
LIB_NAME       := lib$(APP_NAME)_$(QT_ARCH).so
ANDROID_LIB_DIR:= $(BUILD_DIR)/android/libs/$(QT_ARCH)

# ---------- Ambiente Android (exportado para qmake/make) ----------
export ANDROID_SDK_ROOT      := $(HOME)/Android/Sdk
export ANDROID_NDK_ROOT      := $(ANDROID_SDK_ROOT)/ndk/$(NDK_VERSION)
export ANDROID_TOOLCHAIN_PATH:= $(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/linux-x86_64
export ANDROID_NDK_PLATFORM  := android-$(CONF_ANDROID_LEVEL)

# ---------- Targets padrão ----------
.PHONY: all build configure apk clean env

all: build

# Mostra as variáveis importantes (debug)
env:
	@echo "QT_VERSION      = $(QT_VERSION)"
	@echo "QT_ANDROID_DIR  = $(QT_ANDROID_DIR)"
	@echo "QMAKE           = $(QMAKE)"
	@echo "ANDROIDDEPLOYQT = $(ANDROIDDEPLOYQT)"
	@echo "QT_ARCH         = $(QT_ARCH)"
	@echo "WX_ANDROID_ROOT = $(WX_ANDROID_ROOT)"
	@echo "ANDROID_SDK_ROOT= $(ANDROID_SDK_ROOT)"
	@echo "ANDROID_NDK_ROOT= $(ANDROID_NDK_ROOT)"

# ---------- Gera Makefile Android com qmake (somente arm64-v8a) ----------
configure: env
	@echo "==> Gerando Makefile Android em $(BUILD_DIR)..."
	@mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && \
		"$(QMAKE)" -makefile ../minimal.pro \
			WX_ANDROID_ROOT="$(WX_ANDROID_ROOT)" \
			QT_ARCH="$(QT_ARCH)"
	@echo "[OK] Makefile gerado."

# ---------- Compila a .so (lib$(APP_NAME)_arm64-v8a.so) ----------
build: configure
	@echo "==> Compilando projeto (arm64-v8a)..."
	cd $(BUILD_DIR) && $(MAKE)
	@echo "[OK] Build concluído."

# ---------- Gera e instala o APK com androiddeployqt ----------
apk: build
	@echo "==> Preparando biblioteca para androiddeployqt..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@cp "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/"
	@echo "   Copiado $(LIB_NAME) -> $(ANDROID_LIB_DIR)/"
	@echo "==> Executando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)" \
			--install
	@echo "[OK] APK gerado/instalado."

# ---------- Limpeza ----------
clean:
	@echo "==> Limpando diretório de build..."
	rm -rf "$(BUILD_DIR)"
	@echo "[OK] Limpo."

