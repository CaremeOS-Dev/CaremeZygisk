ROOT_DIR ?= .
BUILD_TYPE ?= debug
API_LEVEL ?= 27
ARCHS ?= armeabi-v7a
ARCH ?= armeabi-v7a

# INFO: CaremeZygisk injection path selection.
#   ptrace        = monitor traces init, ptrace-seizes app_process32/zygote, remote-loads libzygisk.so (main path; zero property footprint)
#   native_bridge  = sets ro.dalvik.vm.native.bridge=<loader>, NativeBridgeCallbacks v2 constructor loads payload (backup path; external-observer fingerprint window)
# Both binaries are packaged; runtime switch via /data/adb/caremezygisk/mode.
INJECTION_METHOD ?= ptrace

VER_NAME ?= v1.0.0
VER_CODE ?= $(shell git -C "$(ROOT_DIR)" rev-list HEAD --count 2>/dev/null || echo 1)
COMMIT_HASH ?= $(shell git -C "$(ROOT_DIR)" rev-parse --verify --short HEAD 2>/dev/null || echo unknown)

MIN_APATCH_VERSION ?= 10655
MIN_KSU_VERSION ?= 10940
MIN_KSUD_VERSION ?= 11425
MIN_MAGISK_VERSION ?= 26402

MODULE_ID ?= caremezygisk
MODULE_NAME ?= CaremeZygisk

NDK_VERSION ?= 29.0.13113456
ANDROID_HOME ?= $(HOME)/Android/Sdk
NDK_PATH ?= $(ANDROID_HOME)/ndk/$(NDK_VERSION)
TOOLCHAIN = $(NDK_PATH)/toolchains/llvm/prebuilt/linux-x86_64
SYSROOT = $(TOOLCHAIN)/sysroot

ifeq ($(TERMUX_VERSION),)
	CC = $(TOOLCHAIN)/bin/clang
	AR = $(TOOLCHAIN)/bin/llvm-ar
	STRIP = $(TOOLCHAIN)/bin/llvm-strip
else
	CC = clang
	AR = llvm-ar
	STRIP = llvm-strip
endif

BUILD_DIR ?= $(ROOT_DIR)/build

TARGET_armeabi-v7a = armv7a-linux-androideabi$(API_LEVEL)
# INFO: CaremeZygisk targets pure 32-bit armeabi-v7a only (CaremeOS 2.0 / SDK 27, no arm64 userspace).

CC_ARCH = $(CC) --target=$(TARGET_$(ARCH)) --sysroot=$(SYSROOT)

NDK_CFLAGS = -DANDROID -fdata-sections -ffunction-sections -funwind-tables \
	-fstack-protector-strong -no-canonical-prefixes -D_FORTIFY_SOURCE=2 \
	-Wformat -Werror=format-security
