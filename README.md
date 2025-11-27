O erro `Cannot find android sources in /workspace/kiko/wx-qt-anrdoid-arm64-v8a/android` indica que o **`androiddeployqt` não está encontrando a pasta `android/` com a estrutura necessária**.

## Análise do Problema

O `androiddeployqt` espera encontrar em `ANDROID_PACKAGE_SOURCE_DIR` uma estrutura mínima tipo:

```
android/
  ├── AndroidManifest.xml
  ├── res/
  │   └── values/
  │       └── libs.xml
  └── src/
      └── org/qtproject/example/wxapp/
          └── MainActivity.java
```

## Soluções

### Opção 1: Criar a estrutura mínima (Recomendado)

Crie os arquivos necessários na pasta `android/`:

**1. `android/AndroidManifest.xml`:**
```xml
<?xml version="1.0"?>
<manifest package="org.qtproject.example.wxapp" 
          xmlns:android="http://schemas.android.com/apk/res/android"
          android:versionName="1.0" 
          android:versionCode="1">
    
    <application android:name="org.qtproject.qt5.android.bindings.QtApplication"
                 android:label="WxApp">
        
        <activity android:name="org.qtproject.qt5.android.bindings.QtActivity"
                  android:configChanges="orientation|uiMode|screenLayout|screenSize|smallestScreenSize|layoutDirection|locale|fontScale|keyboard|keyboardHidden|navigation"
                  android:label="WxApp"
                  android:launchMode="singleTop">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <meta-data android:name="android.app.lib_name" android:value="wxapp"/>
        </activity>
    </application>
    
    <uses-sdk android:minSdkVersion="23" android:targetSdkVersion="28"/>
</manifest>
```

**2. `android/res/values/libs.xml`:**
```xml
<?xml version='1.0' encoding='utf-8'?>
<resources>
    <array name="qt_sources">
        <item>https://download.qt.io/ministro/android/qt5/qt-5.15</item>
    </array>
    <array name="bundled_libs">
        <!-- Suas libs nativas serão adicionadas aqui automaticamente -->
    </array>
    <array name="qt_libs">
        <item>Core</item>
        <item>Gui</item>
        <item>Widgets</item>
    </array>
</resources>
```

**3. Criar a estrutura de diretórios:**
```bash
mkdir -p android/res/values
mkdir -p android/src/org/qtproject/example/wxapp
```

### Opção 2: Deixar o androiddeployqt criar a estrutura

Se você **não precisa** de um AndroidManifest customizado agora, pode deixar o `androiddeployqt` criar tudo automaticamente:

**Modifique o `minimal.pro`:**
```qmake
QT += core gui widgets
CONFIG += c++11

TEMPLATE = app
TARGET = wxapp

ANDROID_ABIS = arm64-v8a

SOURCES += $$_PRO_FILE_PWD_/qt_stub.cpp

# REMOVA ou COMENTE esta linha temporariamente:
# ANDROID_PACKAGE_SOURCE_DIR = $$_PRO_FILE_PWD_/android
```

Depois rode:
```bash
make clean
make configure
make build
make apk
```

O `androiddeployqt` vai criar `build_android/android/` com tudo necessário. **Depois** você pode copiar essa estrutura para sua pasta `android/` e customizar.

### Opção 3: Usar --gradle (força criação)

Modifique seu Makefile para adicionar `--gradle`:

```makefile
apk-local:
	@echo "==> Rodando androiddeployqt..."
	cd "$(BUILD_DIR)" && \
	"$(QT_ANDROID_DIR)/bin/androiddeployqt" \
		--input "android-wxapp-deployment-settings.json" \
		--output android \
		--android-platform "android-28" \
		--gradle  # <-- Adicione esta flag
	@echo "[OK] APK gerado."
```

## Verificação Rápida

Execute isto para ver o que está faltando:

```bash
ls -la android/
```

Se não existir `android/AndroidManifest.xml`, crie manualmente com o conteúdo acima, ou deixe o Qt criar automaticamente removendo a linha `ANDROID_PACKAGE_SOURCE_DIR` do `.pro`.

**Recomendação:** Use a **Opção 1** criando a estrutura mínima, pois assim você mantém controle total sobre o manifest e recursos do Android! 🎯
