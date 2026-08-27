#!/system/bin/sh

set -e

MODDIR=${0%/*}
if [ "$ZYGISK_ENABLED" ]; then
  exit 0
fi

cd "$MODDIR"

# INFO: When running on Magisk, manually trigger other Zygisk modules' post-fs-data.sh
#         because Magisk's built-in Zygisk normally re-runs these, but CaremeZygisk
#         disables Magisk's built-in Zygisk (they conflict), so we drive them ourselves.
if [ "$(which magisk)" ]; then
  for file in ../*; do
    if [ -d "$file" ] && [ -d "$file/zygisk" ] && ! [ -f "$file/disable" ]; then
      if [ -f "$file/post-fs-data.sh" ]; then
        cd "$file"
        log -p i -t "zygisk-sh" "Manually trigger post-fs-data.sh for $file"
        sh "$(realpath ./post-fs-data.sh)"
        cd "$MODDIR"
      fi
    fi
  done
fi

create_sys_perm() {
  mkdir -p $1
  chmod 555 $1
  chcon u:object_r:system_file:s0 $1
}

export TMP_PATH=/data/adb/caremezygisk
rm -rf "$TMP_PATH"

create_sys_perm $TMP_PATH

sh /data/adb/post-fs-data.d/caremezygisk.sh

# INFO: CaremeZygisk injection-path selection (dual-path, switchable without rebuild).
#   Mode is read from /data/adb/caremezygisk/mode. Default: ptrace.
#     ptrace        = monitor traces init (PID 1), ptrace-seizes app_process32, remote-loads libzygisk.so.
#                     Main path. Zero property footprint (never touches ro.dalvik.vm.native.bridge).
#     native_bridge = sets ro.dalvik.vm.native.bridge=libzn_loader.so so AndroidRuntime::startVm emits
#                     -XX:NativeBridge=libzn_loader.so and ART LoadNativeBridge loads our NativeBridgeCallbacks v2.
#                     Backup path. After injection the property is reset to 0 to hide the surface.
INJECTION_MODE="ptrace"
if [ -f /data/adb/caremezygisk/mode ]; then
  INJECTION_MODE=$(cat /data/adb/caremezygisk/mode)
fi

case "$INJECTION_MODE" in
  native_bridge)
    log -p i -t "caremezygisk" "Injection mode: native_bridge (backup path)"
    # INFO: CaremeZygisk targets pure 32-bit armeabi-v7a (CaremeOS 8.1, no arm64 userspace).
    #         Only lib/armeabi-v7a is shipped, so the native-bridge loader is placed at the
    #         32-bit system lib path via the module overlay.
    BRIDGE_PROP="ro.dalvik.vm.native.bridge"
    BRIDGE_LOADER="libzn_loader.so"
    if command -v resetprop >/dev/null 2>&1; then
      resetprop "$BRIDGE_PROP" "$BRIDGE_LOADER"
    else
      log -p w -t "caremezygisk" "resetprop not found, native_bridge mode unavailable"
      INJECTION_MODE="ptrace"
    fi
    ;;
  ptrace|*)
    log -p i -t "caremezygisk" "Injection mode: ptrace (main path)"
    ;;
esac

# INFO: ptrace path (and native_bridge fallback) both rely on the ptrace monitor
#         being available to (re-)seize zygote. On native_bridge the monitor is idle
#         but harmless; the loader handles injection itself.
if [ "$INJECTION_MODE" = "ptrace" ]; then
  ./bin/zygisk-ptrace32 monitor &
fi

exit 0
