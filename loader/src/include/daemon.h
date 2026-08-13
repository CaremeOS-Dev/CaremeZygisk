#ifndef DAEMON_H
#define DAEMON_H

#include <stdbool.h>

#include <unistd.h>

enum caremezygiskd_actions {
  ZygoteInjected,
  GetProcessFlags,
  GetInfo,
  ReadModules,
  RequestCompanionSocket,
  GetModuleDir,
  ZygoteRestart,
  UpdateMountNamespace,
  RemoveModule
};

struct zygisk_modules {
  char **modules;
  size_t modules_count;
};

enum root_impl {
  ROOT_IMPL_NONE,
  ROOT_IMPL_APATCH,
  ROOT_IMPL_KERNELSU,
  ROOT_IMPL_MAGISK
};

struct caremezygisk_info {
  struct zygisk_modules modules;
  enum root_impl root_impl;
  pid_t pid;
  bool running;
};

enum mount_namespace_state {
  Clean,
  Mounted
};

#define TMP_PATH "/data/adb/caremezygisk"

static inline const char *caremezygiskd_get_path() {
  return TMP_PATH;
}

bool caremezygiskd_zygote_injected();

uint32_t caremezygiskd_get_process_flags(uid_t uid, const char *const process);

void caremezygiskd_get_info(struct caremezygisk_info *info);

void free_caremezygisk_info(struct caremezygisk_info *info);

bool caremezygiskd_read_modules(struct zygisk_modules *modules);

void free_modules(struct zygisk_modules *modules);

int caremezygiskd_connect_companion(size_t index);

int caremezygiskd_get_module_dir(size_t index);

void caremezygiskd_zygote_restart();

bool caremezygiskd_update_mns(enum mount_namespace_state nms_state, char *buf, size_t buf_size);

bool caremezygiskd_remove_module(size_t index);

#endif /* DAEMON_H */
