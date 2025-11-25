# =============================================================================
# Makefile para compilação Qt6 multi-arquitetura (Linux + Android)
# =============================================================================
# Este Makefile permite compilar projetos Qt6 tanto para Linux (gcc_64) quanto
# para Android em múltiplas arquiteturas (arm64-v8a, armeabi-v7a, x86, x86_64).
# Também fornece comandos úteis para deploy, debug e gerenciamento de apps
# em dispositivos Android conectados via ADB.
# =============================================================================

# ----------  CONFIGURAÇÕES GLOBAIS ----------

# Gradle local (opcional, caso queira usar versão específica)
MY_GRADLE_LOCAL ?= /opt/gradle/gradle-8.10.2/bin/gradle

# SDK do Android
SDK             ?= $(HOME)/Android/Sdk

# Versão das build-tools do Android SDK
VERSION         ?= 36.1.0

# Diretório de build
BUILD_DIR       := build

# Comando Gradle (usa wrapper local do projeto)
GRADLE          := ./gradlew --warning-mode all

# Ferramenta AAPT para extrair informações do APK
AAPT            := $(SDK)/build-tools/$(VERSION)/aapt

# Caminhos dos APKs gerados
apk_debug       := $(BUILD_DIR)/android-build/build/outputs/apk/debug/android-build-debug.apk
apk_release     := $(BUILD_DIR)/android-build/hangman.apk

# APK padrão usado para comandos de device
APK             := $(apk_debug)

# Extrai o nome da Activity principal do APK (usado para start/stop)
# Só executa se o APK existir, evitando erros na primeira execução
ACTIVITYNAME    := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/launchable-activity: name='([^']+).*/\1/p")

# Extrai o nome do pacote do APK (ex: com.example.hangman)
PACKAGE         := $(shell [ -f "$(APK)" ] && $(AAPT) dump badging "$(APK)" 2>/dev/null | sed -nE "s/package: name='([^']+).*/\1/p")

# ----------  CONFIGURAÇÕES Qt E ANDROID ----------

# Versão do Qt instalada
QT_VERSION       ?= 6.10.0

# Diretório base da instalação do Qt
QT_BASE          ?= $(HOME)/Qt

# Caminho do Android NDK
ANDROID_NDK_ROOT ?= $(HOME)/Android/Sdk/ndk/26.1.10909125

# Caminho do Android SDK
ANDROID_SDK_ROOT ?= $(HOME)/Android/Sdk

# ----------- VERBOSE -------------------

VERBOSE          ?= -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
                    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# ----------  KITS DISPONÍVEIS ----------

# Lista de arquiteturas Android suportadas
KITS = arm64_v8a armv7 x86 x86_64

# Kit padrão para build (linux = gcc_64)
BUILD ?= linux

# =============================================================================
# TARGETS PRINCIPAIS
# =============================================================================

.PHONY: all build $(BUILD) clean help info

# Target padrão: exibe ajuda
.DEFAULT_GOAL := help

## help: Exibe esta mensagem de ajuda
help:
	@echo "=========================================="
	@echo "  Makefile Qt6 - Compilação Multi-Plataforma"
	@echo "=========================================="
	@echo ""
	@echo "📋 TARGETS PRINCIPAIS:"
	@echo "  make help              - Exibe esta mensagem"
	@echo "  make info              - Mostra variáveis de ambiente configuradas"
	@echo "  make build             - Compila para Linux (gcc_64)"
	@echo "  make compile           - Compila o projeto configurado"
	@echo "  make run               - Executa o binário Linux compilado"
	@echo "  make clean             - Remove o diretório de build"
	@echo ""
	@echo "🤖 ANDROID - CONFIGURAÇÃO:"
	@echo "  make android-arm64_v8a - Configura build para Android ARM 64-bit"
	@echo "  make android-armv7     - Configura build para Android ARM 32-bit"
	@echo "  make android-x86       - Configura build para Android x86 32-bit"
	@echo "  make android-x86_64    - Configura build para Android x86 64-bit"
	@echo "  make all               - Configura todos os kits Android"
	@echo ""
	@echo "📱 DEVICE - INSTALAÇÃO E CONTROLE:"
	@echo "  make install           - Instala APK debug no device conectado"
	@echo "  make uninstall         - Remove app do device"
	@echo "  make start             - Inicia a activity principal"
	@echo "  make stop              - Para a aplicação"
	@echo "  make back              - Simula tecla 'Voltar'"
	@echo "  make home              - Simula tecla 'Home'"
	@echo ""
	@echo "🔍 DEBUG E INFORMAÇÕES:"
	@echo "  make log               - Mostra logs do app"
	@echo "  make log2              - Mostra logs de erros/crashes"
	@echo "  make abi               - Mostra ABI do device conectado"
	@echo "  make sdk               - Mostra versão SDK do device"
	@echo ""
	@echo "🚀 OUTROS:"
	@echo "  make scp               - Copia APK debug via SCP para servidor"
	@echo ""

## info: Mostra as variáveis de ambiente configuradas
info:
	@echo "=========================================="
	@echo "  VARIÁVEIS DE AMBIENTE"
	@echo "=========================================="
	@echo ""
	@echo "📦 Qt:"
	@echo "  QT_VERSION       = $(QT_VERSION)"
	@echo "  QT_BASE          = $(QT_BASE)"
	@echo "  QT_HOST_PATH     = $(QT_BASE)/$(QT_VERSION)/gcc_64"
	@echo ""
	@echo "🤖 Android SDK/NDK:"
	@echo "  SDK              = $(SDK)"
	@echo "  ANDROID_SDK_ROOT = $(ANDROID_SDK_ROOT)"
	@echo "  ANDROID_NDK_ROOT = $(ANDROID_NDK_ROOT)"
	@echo "  BUILD_TOOLS_VER  = $(VERSION)"
	@echo ""
	@echo "🔧 Build:"
	@echo "  BUILD_DIR        = $(BUILD_DIR)"
	@echo "  BUILD            = $(BUILD)"
	@echo ""
	@echo "📱 APKs:"
	@echo "  apk_debug        = $(apk_debug)"
	@echo "  apk_release      = $(apk_release)"
	@echo ""
	@echo "📲 Device Info (se APK existir):"
	@echo "  PACKAGE          = $(PACKAGE)"
	@echo "  ACTIVITYNAME     = $(ACTIVITYNAME)"
	@echo ""
	@echo "🏗️  Kits disponíveis:"
	@echo "  $(KITS)"
	@echo ""

## build: Compila para o kit especificado em BUILD (padrão: linux)
build: build-$(BUILD)

## all: Configura CMake para todas as arquiteturas Android
all: $(addprefix android-,$(KITS))

# =============================================================================
# ANDROID - DEVICE MANAGEMENT
# =============================================================================

## install: Instala APK debug no device/emulador conectado via ADB
install:
	@echo "📲 Instalando $(apk_debug)..."
	adb logcat -c
	adb install -r $(apk_debug)

## uninstall: Remove o pacote do device
uninstall:
	@echo "🗑️  Desinstalando $(PACKAGE)..."
	adb uninstall $(PACKAGE)

## back: Simula pressionar botão "Voltar"
back:
	adb shell input keyevent KEYCODE_BACK

## home: Simula pressionar botão "Home"
home:
	adb shell input keyevent KEYCODE_HOME

## start: (Re)inicia a Activity principal do app
start:
	@echo "▶️  Iniciando $(PACKAGE)/$(ACTIVITYNAME)..."
	adb shell am start -n $(PACKAGE)/$(ACTIVITYNAME)

## stop: Para a aplicação forçadamente
stop:
	@echo "⏹️  Parando $(PACKAGE)..."
	adb shell am force-stop $(PACKAGE)

## log: Mostra logs do Android filtrados pelo nome do pacote
log:
	@echo "📋 Logs de $(PACKAGE):"
	adb logcat | grep $(PACKAGE)

## log2: Mostra apenas logs de erro, JNI, crashes e sinais do app
log2:
	@echo "🔍 Logs de erro de $(PACKAGE):"
	adb logcat *:E DEBUG:* | grep -E "Fatal|JNI|SIG|$(PACKAGE)"

## abi: Mostra a ABI (arquitetura) do device conectado
abi:
	@echo "🏗️  ABI do device:"
	@adb shell getprop ro.product.cpu.abi

## sdk: Mostra a versão do SDK do device conectado
sdk:
	@echo "📱 SDK do device:"
	@adb shell getprop ro.build.version.sdk

# =============================================================================
# HOST: LINUX (gcc_64)
# =============================================================================

## build-linux: Configura CMake para compilação Linux (gcc_64)
build-linux:
	@echo "🐧 Configurando build para Linux (gcc_64)..."
	PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig \
	cmake \
		-S . \
		-B $(BUILD_DIR)\
		$(VERBOSE) \
		-DCMAKE_PREFIX_PATH=$(QT_BASE)/$(QT_VERSION)/gcc_64

## deploy: Compila projeto Linux do zero (configura + compila)
deploy: build-linux compile

## run: Executa o binário compilado para Linux
run:
	@echo "▶️  Executando aplicação..."
	$(BUILD_DIR)/`sed -n 's/.*qt_add_executable(\([^[:space:]]*\).*/\1/p' CMakeLists.txt`

## compile: Compila o projeto já configurado (usa build/ existente)
compile:
	@echo "🔨 Compilando..."
	cmake --build build

# =============================================================================
# ANDROID - CONFIGURAÇÃO POR ARQUITETURA
# =============================================================================

## android-x86: Configura CMake para Android x86 (32-bit)
android-x86:
	@echo "🤖 Configurando build para Android x86..."
	cmake \
		-S . \
		-B $(BUILD_DIR) \
		$(VERBOSE) \
		-DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=x86 \
		-DANDROID_PLATFORM=android-23 \
		-DCMAKE_PREFIX_PATH=$(QT_BASE)/$(QT_VERSION)/android_x86 \
		-DQT_HOST_PATH=$(QT_BASE)/$(QT_VERSION)/gcc_64 \
		-DANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) \
		-DANDROID_NDK=$(ANDROID_NDK_ROOT) \
		-DCMAKE_FIND_ROOT_PATH=$(QT_BASE)/$(QT_VERSION)/android_x86

## android-arm64_v8a: Configura CMake para Android ARM 64-bit (recomendado)
android: android-arm64_v8a  # alias
android-arm64_v8a:
	@echo "🤖 Configurando build para Android ARM 64-bit..."
	cmake \
		-S . \
		-B $(BUILD_DIR) \
		$(VERBOSE) \
		-DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=arm64-v8a \
		-DANDROID_PLATFORM=android-23 \
		-DCMAKE_PREFIX_PATH=$(QT_BASE)/$(QT_VERSION)/android_arm64_v8a \
		-DQT_HOST_PATH=$(QT_BASE)/$(QT_VERSION)/gcc_64 \
		-DANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) \
		-DANDROID_NDK=$(ANDROID_NDK_ROOT) \
		-DCMAKE_FIND_ROOT_PATH=$(QT_BASE)/$(QT_VERSION)/android_arm64_v8a

fix:
	cp gradle.properties build/android-build

## android-armv7: Configura CMake para Android ARM 32-bit (legacy)
android-armv7:
	@echo "🤖 Configurando build para Android ARM 32-bit..."
	cmake \
		-S . \
		-B $(BUILD_DIR) \
		$(VERBOSE) \
		-DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=armeabi-v7a \
		-DANDROID_PLATFORM=android-23 \
		-DCMAKE_PREFIX_PATH=$(QT_BASE)/$(QT_VERSION)/android_armv7 \
		-DQT_HOST_PATH=$(QT_BASE)/$(QT_VERSION)/gcc_64 \
		-DANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) \
		-DANDROID_NDK=$(ANDROID_NDK_ROOT) \
		-DCMAKE_FIND_ROOT_PATH=$(QT_BASE)/$(QT_VERSION)/android_armv7

## android-x86_64: Configura CMake para Android x86 64-bit
android-x86_64:
	@echo "🤖 Configurando build para Android x86 64-bit..."
	cmake \
		-S . \
		-B $(BUILD_DIR) \
		$(VERBOSE) \
		-DCMAKE_TOOLCHAIN_FILE=$(ANDROID_NDK_ROOT)/build/cmake/android.toolchain.cmake \
		-DANDROID_ABI=x86_64 \
		-DANDROID_PLATFORM=android-23 \
		-DCMAKE_PREFIX_PATH=$(QT_BASE)/$(QT_VERSION)/android_x86_64 \
		-DQT_HOST_PATH=$(QT_BASE)/$(QT_VERSION)/gcc_64 \
		-DANDROID_SDK_ROOT=$(ANDROID_SDK_ROOT) \
		-DANDROID_NDK=$(ANDROID_NDK_ROOT) \
		-DCMAKE_FIND_ROOT_PATH=$(QT_BASE)/$(QT_VERSION)/android_x86_64

# =============================================================================
# LIMPEZA E UTILITÁRIOS
# =============================================================================

## clean: Remove completamente o diretório de build
clean:
	@echo "🧹 Limpando build..."
	rm -rf $(BUILD_DIR)

## scp: Copia APK debug para servidor remoto via SCP
scp: $(apk_debug)
	@echo "📤 Copiando APK para servidor..."
	scp $(apk_debug) dev:www
