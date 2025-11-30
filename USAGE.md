

# Compila para Linux (gcc_64)

```{bash}
  make build             - Compila para Linux (gcc_64)
  make compile           - Compila o projeto configurado
  make run               - Executa o binário Linux compilado
```


```{bash}
  android-platform-manager.sh android-35
  make android-arm64_v8a
  make compile
  make info
==========================================
  VARIÁVEIS DE AMBIENTE
==========================================

📦 Qt:
  QT_VERSION       = 6.10.0
  QT_BASE          = /home/ivan/Qt
  QT_HOST_PATH     = /home/ivan/Qt/6.10.0/gcc_64

🤖 Android SDK/NDK:
  SDK              = /home/ivan/Android/Sdk
  ANDROID_SDK_ROOT = /home/ivan/Android/Sdk
  ANDROID_NDK_ROOT = /home/ivan/Android/Sdk/ndk/26.1.10909125
  BUILD_TOOLS_VER  = 36.1.0

🔧 Build:
  BUILD_DIR        = build
  BUILD            = linux

📱 APKs:
  apk_debug        = build/android-build/build/outputs/apk/debug/android-build-debug.apk
  apk_release      = build/android-build/hangman.apk

📲 Device Info (se APK existir):
  PACKAGE          = org.qtproject.example.hangman
  ACTIVITYNAME     = org.qtproject.qt.android.bindings.QtActivity

🏗️  Kits disponíveis:
  arm64_v8a armv7 x86 x86_64

```

