#!/system/bin/sh

set -e

export TMP_PATH=/data/adb/caremezygisk
rm -rf "$TMP_PATH"

rm -f /data/adb/post-fs-data.d/caremezygisk.sh
rm -f /data/adb/post-mount.d/caremezygisk.sh

# INFO: Only removes if dir is empty
rmdir /data/adb/post-fs-data.d
rmdir /data/adb/post-mount.d

exit 0
