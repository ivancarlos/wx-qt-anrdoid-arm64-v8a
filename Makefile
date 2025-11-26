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

NDK_VERSION        ?= android-ndk-r21e
CONF_ANDROID_LEVEL ?= 28
QT_ARCH            ?= arm64-v8a
CONF_COMPILER_ARCH := aarch64    # para arm64-v8a
WX_ANDROID_ROOT    ?= $(HOME)/wx/android-wx-3.2.4
WX_LIB_DIR         := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib

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
NDKDEPENDS      := $(ANDROID_NDK_ROOT)/build/tools/ndk-depends
READELF         := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# libc++_shared.so no sysroot do toolchain
NDK_CPP_SYSROOT_DIR := $(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/lib$(CONF_COMPILER_ARCH)-linux-android

# libc++_shared.so no diretório llvm-libc++
NDK_CPP_STL_DIR     := $(ANDROID_NDK_ROOT)/sources/cxx-stl/llvm-libc++/libs/$(QT_ARCH)
TOOLCHAIN_LIB_TOOLS := $(ANDROID_NDK_ROOT)/platforms/$(ANDROID_NDK_PLATFORM)/arch-arm64

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
.PHONY: all build configure apk apk-readelf clean env info

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
	mkdir -p $(BUILD_DIR)/android/libs/arm64-v8a
	cp -v $(BUILD_DIR)/libwxapp_arm64-v8a.so $(BUILD_DIR)/android/libs/arm64-v8a
	@echo "[OK] Build concluído."


# ---------- Helper: encontra dependências recursivamente com readelf ----------
.PHONY: find-deps-readelf
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
		for P in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)" "$(BUILD_DIR)"; do \
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

# ---------- Copia dependências encontradas para android/libs ----------
.PHONY: copy-deps
copy-deps:
	@echo " 🟩($@)🟩🟩🟩🟩🟩🟩🟩🟩🟩"
	@if [ ! -f "$(BUILD_DIR)/all-deps.txt" ]; then \
		echo "❌ Erro: execute 'make find-deps-readelf' primeiro!"; \
		exit 1; \
	fi
	@echo "📦 Copiando dependências para $(ANDROID_LIB_DIR)..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		COPIED=0; \
		for search_path in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)" "$(BUILD_DIR)"; do \
			if [ -f "$$search_path/$$dep" ]; then \
				echo "  ✅ $$dep <- $$search_path"; \
				echo cp -v "$$search_path/$$dep" "$(ANDROID_LIB_DIR)/"; \
				cp -v "$$search_path/$$dep" "$(ANDROID_LIB_DIR)/" || true; \
				COPIED=1; \
				break; \
			fi; \
		done; \
		[ $$COPIED -eq 0 ] && echo "  ⚠️  Não encontrado: $$dep"; \
	done < "$(BUILD_DIR)/all-deps.txt"

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
	#copy_with_check "$(BUILD_DIR)/libwxapp_arm64-v8a.so" "$(BUILD_DIR)/android/libs/arm64-v8a"; \
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

# ---------- Gera APK com androiddeployqt (usando readelf) ----------
apk-readelf: build find-deps-readelf copy-deps copy-deps-check
	@echo "==> Executando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)"
	@echo "[OK] APK gerado com dependências completas (readelf)."

# ---------- Gera APK original (mantido para compatibilidade) ----------
apk: apk-readelf

# ---------- Verifica libs dentro do APK gerado ----------
.PHONY: verify-apk
verify-apk:
	@if [ ! -f "$(APK)" ]; then \
		echo "❌ APK não encontrado: $(APK)"; \
		echo "   Execute 'make apk' ou 'make apk-readelf' primeiro."; \
		exit 1; \
	fi
	@echo "🔍 Bibliotecas dentro do APK:"
	@unzip -l "$(APK)" | grep "lib/$(QT_ARCH)/" | grep "\.so$$" | awk '{print $$4}' | sort
	@echo ""
	@echo "📊 Total de libs:"
	@unzip -l "$(APK)" | grep "lib/$(QT_ARCH)/" | grep "\.so$$" | wc -l

# ---------- Verifica dependências faltantes no APK ----------
.PHONY: verify-missing
verify-missing:
	@if [ ! -f "$(APK)" ]; then \
		echo "❌ APK não encontrado: $(APK)"; \
		exit 1; \
	fi
	@echo "⚠️  Verificando dependências faltantes..."
	@TMP_DIR=$$(mktemp -d); \
	unzip -q "$(APK)" "lib/$(QT_ARCH)/*.so" -d "$$TMP_DIR" 2>/dev/null || true; \
	MISSING=0; \
	for lib in $$TMP_DIR/lib/$(QT_ARCH)/*.so; do \
		[ ! -f "$$lib" ] && continue; \
		DEPS=$$($(READELF) -d "$$lib" 2>/dev/null | grep NEEDED | awk '{print $$5}' | tr -d '[]'); \
		for dep in $$DEPS; do \
			if [ ! -f "$$TMP_DIR/lib/$(QT_ARCH)/$$dep" ]; then \
				echo "  ❌ $$(basename $$lib) precisa de: $$dep"; \
				MISSING=$$((MISSING + 1)); \
			fi; \
		done; \
	done; \
	rm -rf "$$TMP_DIR"; \
	if [ $$MISSING -eq 0 ]; then \
		echo "✅ Nenhuma dependência faltando!"; \
	else \
		echo ""; \
		echo "⚠️  Total de dependências faltantes: $$MISSING"; \
	fi

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
	@echo "  READELF          = $(READELF)"
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
delete-data:
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
