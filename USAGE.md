Segue o Makefile reescrito inteiro, já com:

* `deps-main` para listar dependências da lib principal.
* `deps-apk` para listar dependências das `.so` dentro do APK.
* `apk` agora **vira alias de `apk-readelf`** (ou seja, usa o pipeline robusto com `readelf` + `copy-deps`, não usa mais `ndk-depends` pra montar libs).

```make
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

# Ferramentas auxiliares
AAPT            := $(ANDROID_SDK_ROOT)/build-tools/$(VERSION)/aapt
NDKDEPENDS      := $(ANDROID_NDK_ROOT)/build/tools/ndk-depends
READELF         := $(ANDROID_TOOLCHAIN_PATH)/bin/llvm-readelf

# libc++_shared.so no sysroot do toolchain
NDK_CPP_SYSROOT_DIR := $(ANDROID_TOOLCHAIN_PATH)/sysroot/usr/lib$(CONF_COMPILER_ARCH)-linux-android

# libc++_shared.so no diretório llvm-libc++
NDK_CPP_STL_DIR     := $(ANDROID_NDK_ROOT)/sources/cxx-stl/llvm-libc++/libs/$(QT_ARCH)

# Caminhos dos APKs gerados
apk_debug       := build/android/build/outputs/apk/debug/android-debug.apk
apk_release     := build/android/build/outputs/apk/release/android-release.apk

# APK padrão usado para comandos de device
APK             := $(apk_debug)

# Extrai o nome da Activity principal do APK (usado para start/stop)
ACTIVITYNAME    := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")

# Extrai o nome do pacote do APK
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
	@echo "[OK] Build concluído."

# ---------- Lista dependências diretas da lib principal ----------
.PHONY: deps-main
deps-main: build
	@mkdir -p "$(BUILD_DIR)"
	@echo "NEEDED de $(LIB_NAME) (lib principal) :" > "$(BUILD_DIR)/deps-main.txt"
	@$(READELF) -d "$(BUILD_DIR)/$(LIB_NAME)" 2>/dev/null | \
		grep NEEDED | awk '{print $$5}' | tr -d '[]' | sort -u >> "$(BUILD_DIR)/deps-main.txt"
	@echo ""
	@echo "📄 Dependências salvas em $(BUILD_DIR)/deps-main.txt"
	@cat "$(BUILD_DIR)/deps-main.txt"

# ---------- Helper: encontra dependências recursivamente com ndk-depends (mantido para testes) ----------
.PHONY: find-deps-recursive
find-deps-recursive:
	@echo "🔍 Descobrindo dependências recursivamente com ndk-depends..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@cp "$(BUILD_DIR)/$(LIB_NAME)" "$(ANDROID_LIB_DIR)/" 2>/dev/null || true
	@SEARCH_PATHS="-L $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib -L $(QT_ANDROID_DIR)/lib -L $(NDK_CPP_SYSROOT_DIR) -L $(NDK_CPP_STL_DIR)"; \
	PROCESSED=""; \
	TO_PROCESS="$(LIB_NAME)"; \
	while [ -n "$$TO_PROCESS" ]; do \
		CURRENT=$$(echo "$$TO_PROCESS" | awk '{print $$1}'); \
		TO_PROCESS=$$(echo "$$TO_PROCESS" | sed 's/^[^ ]* *//'); \
		echo "$$PROCESSED" | grep -qw "$$CURRENT" && continue; \
		PROCESSED="$$PROCESSED $$CURRENT"; \
		LIB_PATH="$(ANDROID_LIB_DIR)/$$CURRENT"; \
		if [ -f "$$LIB_PATH" ]; then \
			echo "  📦 Analisando: $$CURRENT"; \
			NEW_DEPS=$$($(NDKDEPENDS) $$SEARCH_PATHS "$$LIB_PATH" 2>/dev/null | awk '{print $$1}' | grep -v "^$$CURRENT$$" || true); \
			for dep in $$NEW_DEPS; do \
				echo "$$PROCESSED $$TO_PROCESS" | grep -qw "$$dep" || TO_PROCESS="$$TO_PROCESS $$dep"; \
			done; \
		fi; \
	done; \
	echo "$$PROCESSED" | tr ' ' '\n' | grep -v '^$$' | sort -u > "$(BUILD_DIR)/all-deps.txt"; \
	echo ""; \
	echo "✅ Dependências completas:"; \
	cat "$(BUILD_DIR)/all-deps.txt"

# ---------- Helper: encontra dependências recursivamente com readelf ----------
.PHONY: find-deps-readelf
find-deps-readelf:
	@echo "🔍 Descobrindo dependências recursivamente com readelf..."
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
		for search_path in "$(ANDROID_LIB_DIR)" "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$search_path/$$LIB" ]; then \
				echo "  📦 Analisando: $$LIB (em $$search_path)"; \
				DEPS=$$($(READELF) -d "$$search_path/$$LIB" 2>/dev/null | grep NEEDED | awk '{print $$5}' | tr -d '[]' || true); \
				ALL_LIBS="$$ALL_LIBS $$DEPS"; \
				FOUND=1; \
				break; \
			fi; \
		done; \
		[ $$FOUND -eq 0 ] && echo "  ⚠️  Não encontrado: $$LIB"; \
	done; \
	echo "$$CHECKED" | tr ' ' '\n' | grep -v '^$$' | sort -u > "$(BUILD_DIR)/all-deps-readelf.txt"; \
	echo ""; \
	echo "✅ Dependências completas (readelf):"; \
	cat "$(BUILD_DIR)/all-deps-readelf.txt"

# ---------- Copia dependências encontradas para android/libs ----------
.PHONY: copy-deps
copy-deps:
	@if [ ! -f "$(BUILD_DIR)/all-deps-readelf.txt" ]; then \
		echo "❌ Erro: execute 'make find-deps-readelf' primeiro!"; \
		exit 1; \
	fi
	@echo "📦 Copiando dependências para $(ANDROID_LIB_DIR)..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		COPIED=0; \
		for search_path in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$search_path/$$dep" ]; then \
				echo "  ✅ $$dep <- $$search_path"; \
				cp -v "$$search_path/$$dep" "$(ANDROID_LIB_DIR)/" || true; \
				COPIED=1; \
				break; \
			fi; \
		done; \
		[ $$COPIED -eq 0 ] && echo "  ⚠️  Não encontrado: $$dep"; \
	done < "$(BUILD_DIR)/all-deps-readelf.txt"

# ---------- Gera APK com androiddeployqt (usando readelf) ----------
apk-readelf: build find-deps-readelf copy-deps
	@echo "==> Executando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
		"$(ANDROIDDEPLOYQT)" \
			--input "$(DEPLOY_JSON)" \
			--output android \
			--android-platform "$(ANDROID_NDK_PLATFORM)"
	@echo "[OK] APK gerado com dependências completas (readelf)."

# ---------- apk: alias para o fluxo robusto (readelf) ----------
apk: apk-readelf

# ---------- Lista libs e dependências dentro do APK ----------
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

# ---------- Lista dependências de todas as .so dentro do APK ----------
.PHONY: deps-apk
deps-apk:
	@if [ ! -f "$(APK)" ]; then \
		echo "❌ APK não encontrado: $(APK)"; \
		echo "   Execute 'make apk' ou 'make apk-readelf' primeiro."; \
		exit 1; \
	fi
	@echo "🔍 Extraindo libs do APK e listando NEEDED..."
	@TMP_DIR=$$(mktemp -d); \
	unzip -q "$(APK)" "lib/$(QT_ARCH)/*.so" -d "$$TMP_DIR" 2>/dev/null || true; \
	OUT_FILE="$(BUILD_DIR)/deps-apk.txt"; \
	mkdir -p "$(BUILD_DIR)"; \
	echo "Dependências NEEDED das libs dentro do APK:" > "$$OUT_FILE"; \
	for lib in $$TMP_DIR/lib/$(QT_ARCH)/*.so; do \
		[ ! -f "$$lib" ] && continue; \
		echo "" >> "$$OUT_FILE"; \
		echo "=== $$(basename $$lib) ===" >> "$$OUT_FILE"; \
		$(READELF) -d "$$lib" 2>/dev/null | grep NEEDED | awk '{print $$5}' | tr -d "[]" | sort -u >> "$$OUT_FILE"; \
	done; \
	rm -rf "$$TMP_DIR"; \
	echo "📄 Dependências do APK salvas em $$OUT_FILE"; \
	cat "$$OUT_FILE"

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

# ---------- info: Mostra as variáveis de ambiente configuradas + APK ----------
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

# ---------- log2: Mostra apenas logs de erro, JNI, crashes e sinais do app ----------
log2:
	@echo "🔍 Logs de erro de $(PACKAGE):"
	adb logcat *:E DEBUG:* | grep -E "Fatal|JNI|SIG|$(PACKAGE)"

# ---------- abi: Mostra a ABI (arquitetura) do device conectado ----------
abi:
	@echo "🏗️  ABI do device:"
	@adb shell getprop ro.product.cpu.abi

# ---------- sdk: Mostra a versão do SDK do device conectado ----------
sdk:
	@echo "📱 SDK do device:"
	@adb shell getprop ro.build.version.sdk

# eof
```

Sugestão pra testar esse “novo ciclo”:

```bash
make clean
make deps-main        # só pra conferir a lista de NEEDED
make apk              # agora usa apk-readelf
make verify-apk
make deps-apk         # se quiser ver dependências de cada .so
```

Se der algum erro estranho do `readelf` ou faltar alguma lib nos diretórios que definimos, me manda a saída e ajustamos os caminhos finos.



Boa, agora temos o sintoma claro:

```txt
java.lang.UnsatisfiedLinkError: dlopen failed: library "libwx_qtu_core-3.2-Android_arm64-v8a.so" not found:
needed by .../libwxapp_arm64-v8a.so
```

Traduzindo:
👉 o **loader do Android não achou `libwx_qtu_core-3.2-Android_arm64-v8a.so` dentro do app**, então na hora de carregar `libwxapp_arm64-v8a.so` ele cai com `UnsatisfiedLinkError`.

Isso só pode ser uma destas coisas:

1. A lib **não está dentro do APK** (não foi empacotada).
2. Ela está no APK mas **com outro nome/caminho** (bem improvável aqui).
3. Tem no APK, mas em um lugar onde o loader não procura (tipo subpasta estranha, também improvável se o `androiddeployqt` montou).

Na prática: quase certo que o APK não está carregando essa `.so`.

---

## 1. O que eu vou supor e arrumar direto

Pra não ficar só no “me manda a saída do comando X”, vou ajustar o Makefile pra:

* Continuar usando o fluxo robusto com `readelf`.
* **Forçar explicitamente** a cópia das duas libs principais do wx:

  * `libwx_qtu_core-3.2-Android_arm64-v8a.so`
  * `libwx_baseu-3.2-Android_arm64-v8a.so`

Mesmo que, por alguma razão, elas não apareçam na lista de `all-deps-readelf.txt`.

Isso garante que essas duas **sempre** vão parar em `build/android/libs/arm64-v8a/`, e o `androiddeployqt` vai incluí-las no APK.

Vou te passar só o trecho do `copy-deps` atualizado, pra você substituir naquele Makefile grandão que eu enviei antes.

---

## 2. Novo `copy-deps` (com “força bruta” pros wx)

Substitua **apenas** o alvo `copy-deps` do Makefile por este:

```make
# ---------- Copia dependências encontradas para android/libs ----------
.PHONY: copy-deps
copy-deps:
	@if [ ! -f "$(BUILD_DIR)/all-deps-readelf.txt" ]; then \
		echo "❌ Erro: execute 'make find-deps-readelf' primeiro!"; \
		exit 1; \
	fi
	@echo "📦 Copiando dependências para $(ANDROID_LIB_DIR)..."
	@mkdir -p "$(ANDROID_LIB_DIR)"
	@while read dep; do \
		[ -z "$$dep" ] && continue; \
		COPIED=0; \
		for search_path in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" "$(NDK_CPP_STL_DIR)" "$(NDK_CPP_SYSROOT_DIR)"; do \
			if [ -f "$$search_path/$$dep" ]; then \
				echo "  ✅ $$dep <- $$search_path"; \
				cp -v "$$search_path/$$dep" "$(ANDROID_LIB_DIR)/" || true; \
				COPIED=1; \
				break; \
			fi; \
		done; \
		[ $$COPIED -eq 0 ] && echo "  ⚠️  Não encontrado (na lista): $$dep"; \
	done < "$(BUILD_DIR)/all-deps-readelf.txt"

	@echo ""
	@echo "🔧 Forçando cópia das libs wx principais (se existirem)..."
	@for extra in \
		libwx_qtu_core-3.2-Android_$(QT_ARCH).so \
		libwx_baseu-3.2-Android_$(QT_ARCH).so; do \
		FOUND=0; \
		for search_path in "$(WX_LIB_DIR)" "$(QT_ANDROID_DIR)/lib" ; do \
			if [ -f "$$search_path/$$extra" ]; then \
				echo "  ✅ (forçado) $$extra <- $$search_path"; \
				cp -v "$$search_path/$$extra" "$(ANDROID_LIB_DIR)/" || true; \
				FOUND=1; \
				break; \
			fi; \
		done; \
		if [ $$FOUND -eq 0 ]; then \
			echo "  ⚠️  (forçado) $$extra não encontrado em WX/Qt libs"; \
		fi; \
	done
```

Repara nesses pontos:

* `WX_LIB_DIR` já está definido como:

  ```make
  WX_LIB_DIR := $(WX_ANDROID_ROOT)/$(QT_ARCH)/usr/lib
  ```

  que é exatamente onde você já tinha as `.so` (`EXTRA_WX_LIBS` antigo mostrava isso).
* Eu usei o padrão:

  ```make
  libwx_qtu_core-3.2-Android_$(QT_ARCH).so
  libwx_baseu-3.2-Android_$(QT_ARCH).so
  ```

  → para `QT_ARCH = arm64-v8a`, vira exatamente:

  * `libwx_qtu_core-3.2-Android_arm64-v8a.so`
  * `libwx_baseu-3.2-Android_arm64-v8a.so`

Se por acaso o nome do arquivo for *ligeiramente* diferente, esse laço “forçado” já vai te imprimir:

```txt
⚠️  (forçado) libwx_qtu_core-3.2-Android_arm64-v8a.so não encontrado em WX/Qt libs
```

e a gente ajusta o nome depois.

---

## 3. Sequência pra testar

Depois de atualizar o `copy-deps`:

```bash
make clean
make apk          # ainda é alias de apk-readelf
make verify-apk
```

No `make verify-apk`, veja se na listagem aparece algo assim:

```txt
lib/arm64-v8a/libwx_qtu_core-3.2-Android_arm64-v8a.so
lib/arm64-v8a/libwx_baseu-3.2-Android_arm64-v8a.so
...
```

Se aparecerem e **mesmo assim** o Android reclamar que “libwx_qtu_core… not found”, aí é outro tipo de problema (namespace/linker).
Mas 99% das vezes, só de garantir que essas `.so` estão no APK, o `UnsatisfiedLinkError` some.

Se quiser, me manda a saída do:

```bash
make apk
make verify-apk
make log2
```

na próxima rodada, que a gente faz o ajuste fino (nomes exatos / pasta / etc.), mas com esse `copy-deps` você já deve ver uma boa diferença.



Show, isso vai ajudar **muito** a enxergar o que está acontecendo dentro do wx.
Vou te passar a “linha de montagem” do que fazer assim que esse build terminar.

---

## 1. Conferir se as novas libs têm símbolos

Depois que o `cmake --build . --target install` terminar, dá uma olhada em uma das libs, por exemplo:

```bash
cd /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib

# ver se aparecem símbolos legíveis
nm libwx_baseu-3.2-Android_arm64-v8a.so | head

# ou:
readelf -Ws libwx_baseu-3.2-Android_arm64-v8a.so | head
```

Se vier um monte de `wxAlgo`, `wxLog`, `wxMutex` etc. (e não só símbolos do tipo `__bss_start`, `_init`), está ótimo.

Se ainda parecer muito “pelado”, vale forçar isso no CMake:

```cmake
-DCMAKE_BUILD_TYPE=Debug \
-DCMAKE_C_FLAGS="-g -O0" \
-DCMAKE_CXX_FLAGS="-g -O0" \
-DCMAKE_STRIP="" \
```

---

## 2. Gerar o APK de novo com as libs de debug

No projeto do app:

```bash
cd /workspace/obs/kiko-nova-abordagem  # ajuste pro teu path real

make clean
make apk       # (já é alias de apk-readelf)
make verify-apk
```

Confere se o APK ainda contém as libs wx no lugar certo:

```bash
make verify-apk | egrep 'libwx_(baseu|qtu_core)'
```

---

## 3. Deixar o app cair de novo e pegar os PCs

Roda:

```bash
make run
make log2
```

Anota de novo o `pc` do frame #01 ou #02 em `libwx_baseu-3.2-Android_arm64-v8a.so`
(pode ser o mesmo `0x318f48` ou outro valor).

---

## 4. Rodar o `addr2line` de verdade

No diretório das libs wx:

```bash
cd /home/ivan/wx/android-wx-3.2.4/arm64-v8a/usr/lib

PC=0x318f48   # substitui pelo pc que aparecer no tombstone

/home/ivan/Android/Sdk/ndk/android-ndk-r21e/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-addr2line \
    -f -C -e libwx_baseu-3.2-Android_arm64-v8a.so $PC
```

Se os símbolos estiverem ok, agora deve sair algo tipo:

```txt
wxAlgumaCoisa
/path/to/src/common/xxxx.cpp:linha
```

Aí a gente passa de “tá morrendo em wxLog/mutex em geral” para
“tá morrendo *exatamente aqui* nesse arquivo/linha do wx”, e dá pra:

* saber se é um assert / abort explícito;
* ou se é um bug de inicialização estática;
* ou ainda alguma incompatibilidade de runtime.

Quando tiver o `arquivo:linha` do `addr2line`, manda que eu te ajudo a interpretar o trecho específico do wx.

