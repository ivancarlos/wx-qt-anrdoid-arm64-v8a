# ============================================================
# Makefile simples para:
#  - gerar Makefile Android com qmake
#  - compilar libwxapp_arm64-v8a.so
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
WX_LIB_DIR          := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib

# Arquivo de deployment gerado pelo qmake
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

# Versão das build-tools do Android SDK (ajuste se necessário: use uma que você tenha instalado)
VERSION         ?= 36.1.0

# Comando Gradle (wrapper local do projeto, se um dia quiser usar)
GRADLE          := ./gradlew --warning-mode all

# Ferramenta AAPT para extrair informações do APK
AAPT            := $(ANDROID_SDK_ROOT)/build-tools/$(VERSION)/aapt

# Caminhos dos APKs gerados
apk_debug       := build/android/build/outputs/apk/debug/android-debug.apk
apk_release     := build/android/build/outputs/apk/release/android-release.apk

# APK padrão usado para comandos de device
APK             := $(apk_debug)

# Extrai o nome da Activity principal do APK (usado para start/stop)
# Só executa se o APK existir, evitando erros na primeira execução
ACTIVITYNAME    := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")

# Extrai o nome do pacote do APK (ex: com.example.hangman)
PACKAGE         := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/package: name='([^']+).*/\1/p")

# ---------- Targets padrão ----------
.PHONY: all build configure apk clean env info

all: build

# Mostra as variáveis importantes (debug rápido)
env:
	@echo "QT_VERSION       = $(QT_VERSION)"
	@echo "QT_ANDROID_DIR   = $(QT_ANDROID_DIR)"
	@echo "QMAKE            = $(QMAKE)"
	@echo "ANDROIDDEPLOYQT  = $(ANDROIDDEPLOYQT)"
	@echo "QT_ARCH          = $(QT_ARCH)"
	@echo "WX_ANDROID_ROOT  = $(WX_ANDROID_ROOT)"
	@echo "ANDROID_SDK_ROOT = $(ANDROID_SDK_ROOT)"
	@echo "ANDROID_NDK_ROOT = $(ANDROID_NDK_ROOT)"

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
	cd "$(BUILD_DIR)" && $(MAKE)
	@echo "[OK] Build concluído."

# ---------- Gera e instala o APK com androiddeployqt ----------
apk: build
	@echo "==> Preparando biblioteca para androiddeployqt..."
	@mkdir -p "$(ANDROID_LIB_DIR)"

	# Copia a lib principal do app
	@cp "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/"
	@echo "   Copiado $(LIB_NAME) -> $(ANDROID_LIB_DIR)/"

	# Copia as bibliotecas do wxWidgets necessárias
	@echo "==> Copiando bibliotecas wxWidgets para o APK..."
	@cp "$(WX_LIB_DIR)"/libwx_qtu_*-3.2-Android_$(QT_ARCH).so "$(ANDROID_LIB_DIR)/" 2>/dev/null || true
	@cp "$(WX_LIB_DIR)"/libwx_baseu*-3.2-Android_$(QT_ARCH).so "$(ANDROID_LIB_DIR)/" 2>/dev/null || true

	@echo "   Conteúdo de $(ANDROID_LIB_DIR):"
	@ls -1 "$(ANDROID_LIB_DIR)"

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

## info: Mostra as variáveis de ambiente configuradas + APK
info:
	@echo "=========================================="
	@echo "  VARIÁVEIS DE AMBIENTE / BUILD"
	@echo "=========================================="
	@echo ""
	@echo "📦 Qt:"
	@echo "  QT_VERSION       = $(QT_VERSION)"
	@echo "  QT_ANDROID_DIR   = $(QT_ANDROID_DIR)"
	@echo "  QMAKE            = $(QMAKE)"
	@echo "  ANDROIDDEPLOYQT  = $(ANDROIDDEPLOYQT)"
	@echo ""
	@echo "🤖 Android SDK/NDK:"
	@echo "  ANDROID_SDK_ROOT = $(ANDROID_SDK_ROOT)"
	@echo "  ANDROID_NDK_ROOT = $(ANDROID_NDK_ROOT)"
	@echo "  ANDROID_NDK_PLATFORM = $(ANDROID_NDK_PLATFORM)"
	@echo "  BUILD_TOOLS_VER  = $(VERSION)"
	@echo "  AAPT             = $(AAPT)"
	@echo ""
	@echo "🔧 Build:"
	@echo "  PROJECT_ROOT     = $(PROJECT_ROOT)"
	@echo "  BUILD_DIR        = $(BUILD_DIR)"
	@echo "  LIB_NAME         = $(LIB_NAME)"
	@echo "  ANDROID_LIB_DIR  = $(ANDROID_LIB_DIR)"
	@echo "  DEPLOY_JSON      = $(DEPLOY_JSON)"
	@echo ""
	@echo "📱 APKs:"
	@echo "  apk_debug        = $(apk_debug)"
	@echo "  apk_release      = $(apk_release)"
	@echo "  APK (ativo)      = $(APK)"
	@echo ""
	@echo "📲 Device Info (se APK existir):"
	@echo "  PACKAGE          = $(PACKAGE)"
	@echo "  ACTIVITYNAME     = $(ACTIVITYNAME)"
	@echo ""

# ---------- Instala o APK no dispositivo ----------
install:
	@if [ -z "$(APK)" ] || [ ! -f "$(APK)" ]; then \
		echo "[ERRO] APK não encontrado. Rode 'make apk' primeiro."; \
		exit 1; \
	fi
	@echo "==> Instalando APK..."
	adb install -r "$(APK)"
	@echo "[OK] APK instalado."

# ---------- Desinstala o APP do dispositivo ----------
uninstall:
	@if [ -z "$(PACKAGE)" ]; then \
		echo "[ERRO] PACKAGE não encontrado no APK."; \
		echo "       Execute 'make info' para verificar."; \
		exit 1; \
	fi
	@echo "==> Removendo pacote $(PACKAGE)..."
	adb uninstall "$(PACKAGE)" || true
	@echo "[OK] App desinstalado."

# ---------- Força parada do app no dispositivo ----------
kill:
	@if [ -z "$(PACKAGE)" ]; then \
		echo "[ERRO] PACKAGE não encontrado. Rode 'make info' para ver detalhes."; \
		exit 1; \
	fi
	@echo "==> Forçando parada do app $(PACKAGE)..."
	adb shell am force-stop "$(PACKAGE)"
	@echo "[OK] App parado."


# ---------- Limpa dados do app ----------
clear-data:
	@if [ -z "$(PACKAGE)" ]; then \
		echo "[ERRO] PACKAGE não encontrado."; \
		exit 1; \
	fi
	@echo "==> Limpando dados do app $(PACKAGE)..."
	adb shell pm clear "$(PACKAGE)"
	@echo "[OK] Dados limpos."


# ---------- Logcat filtrado pelo pacote ----------
logcat:
	@if [ -z "$(PACKAGE)" ]; then \
		echo "[ERRO] PACKAGE não encontrado. Rode 'make info'."; \
		exit 1; \
	fi
	@echo "==> Logcat filtrado pelo pacote $(PACKAGE)..."
	adb logcat | grep --line-buffered "$(PACKAGE)"


# ---------- Instala e inicia o app ----------
run: install
	@if [ -z "$(PACKAGE)" ] || [ -z "$(ACTIVITYNAME)" ]; then \
		echo "[ERRO] PACKAGE ou ACTIVITYNAME não encontrados no APK."; \
		echo "       Rode: make info"; \
		exit 1; \
	fi
	@echo "==> Iniciando $(PACKAGE)/$(ACTIVITYNAME)..."
	adb shell am start -n "$(PACKAGE)/$(ACTIVITYNAME)"
	@echo "[OK] App iniciado."

# ---------- log2: Mostra apenas logs de erro, JNI, crashes e sinais do app
log2:
	@echo "🔍 Logs de erro de $(PACKAGE):"
	adb logcat *:E DEBUG:* | grep -E "Fatal|JNI|SIG|$(PACKAGE)"

# ---------- abi: Mostra a ABI (arquitetura) do device conectado
abi:
	@echo "🏗️  ABI do device:"
	@adb shell getprop ro.product.cpu.abi

# ---------- sdk: Mostra a versão do SDK do device conectado
sdk:
	@echo "📱 SDK do device:"
	@adb shell getprop ro.build.version.sdk

# eof
