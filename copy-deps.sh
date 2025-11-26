#!/usr/bin/env bash
# copy-deps.sh - Descobre e copia dependências nativas para o APK

set -e # Para em caso de erro

# Argumentos
NDKDEPENDS="$1"
LIB_FILE="$2"
ANDROID_LIB_DIR="$3"
WX_LIB_DIR="$4"
WX_BIN_DIR="$5"
QT_LIB_DIR="$6"
NDK_CPP_SYSROOT_DIR="$7"
NDK_CPP_STL_DIR="$8"

# Valida argumentos
if [ -z "$NDKDEPENDS" ] || [ -z "$LIB_FILE" ] || [ -z "$ANDROID_LIB_DIR" ]; then
    echo "Uso: $0 <ndk-depends> <lib-file> <android-lib-dir> <wx-lib-dir> <wx-bin-dir> <qt-lib-dir> <ndk-sysroot> <ndk-stl>"
    exit 1
fi

echo "🔍 Descobrindo dependências nativas com ndk-depends..."

# Descobre dependências
"$NDKDEPENDS" \
    -L "$WX_LIB_DIR" \
    -L "$QT_LIB_DIR" \
    "$LIB_FILE" 2>/dev/null | awk '{print $1}' | sort -u >/tmp/deps.txt || true

echo "   Dependências encontradas:"
cat /tmp/deps.txt

echo ""
echo "📦 Copiando dependências para $ANDROID_LIB_DIR..."

COPIED=0
SKIPPED=0

while IFS= read -r dep; do
    # Ignora linhas vazias
    [ -z "$dep" ] && continue

    FOUND=false

    # Busca nos caminhos (ordem de prioridade)
    for search_path in \
        "$WX_LIB_DIR/$dep" \
        "$WX_BIN_DIR/$dep" \
        "$QT_LIB_DIR/$dep" \
        "$NDK_CPP_SYSROOT_DIR/$dep" \
        "$NDK_CPP_STL_DIR/$dep"; do

        if [ -f "$search_path" ]; then
            echo "  ✅ $dep <- $search_path"
            cp -f "$search_path" "$ANDROID_LIB_DIR/"
            FOUND=true
            ((COPIED++))
            break
        fi
    done

    if [ "$FOUND" = false ]; then
        echo "  ⚠️  Ignorado (sistema): $dep"
        ((SKIPPED++))
    fi

done </tmp/deps.txt

echo ""
echo "📊 Resumo:"
echo "   ✅ Libs copiadas: $COPIED"
echo "   ⚠️  Libs do sistema ignoradas: $SKIPPED"

rm -f /tmp/deps.txt

exit 0
