# CaremeZygisk

面向 **CaremeOS 8.1**（基于 Android 8.1 / SDK 27 的小天才 / XTC 儿童手表 ROM）的**设备专用 Zygisk**。已在 **CaremeOS 1.0 与 2.0** 上测试可用 —— 版本号按 Android 底座 8.1 命名，而非某一个 CaremeOS 发行版本。

基底为 [ReZygisk](https://github.com/PerformanC/ReZygisk)（Zygisk 的独立 C 实现），针对 CaremeOS 的魔改 framework、纯 32 位环境与厂商检测做了适配。

## 目标设备与约束

- **系统**：CaremeOS 8.1（Android 8.1 / SDK 27），已测 CaremeOS 1.0、2.0
- **架构**：纯 32 位，仅 `armeabi-v7a`（无 arm64 用户空间，只有 `app_process32`）
- **Root**：三根兼容 —— Magisk / KernelSU / APatch
- **SELinux**：宽容（permissive）

## 能做什么

- 加载现有 Zygisk 模块（如 LSPosed / Vector）—— 完整 Zygisk API v5 兼容
- 隐藏 root / DenyList（mount 命名空间隔离）
- 绕过 CaremeOS 自身的注入 / 调试检测
- Zygisk 自身隐藏（loader 库、daemon、ptrace 痕迹）

## 注入方式（双路并存）

构建期同时打包两条注入路径，运行期通过 `/data/adb/caremezygisk/mode` 切换：

- **ptrace（主）**：monitor 追踪 init，捕获 `app_process32`，ptrace-seize zygote，远程加载 `libzygisk.so`。不触碰 `ro.dalvik.vm.native.bridge`，属性零痕迹。
- **native-bridge（备）**：设 `ro.dalvik.vm.native.bridge`，NativeBridgeCallbacks v2 构造器加载 payload；外部观察者存在一次指纹窗口。

## 依赖

| 工具 | 说明 |
|------|------|
| Android NDK | `29.0.13113456`（见 `common.mk` 的 `NDK_VERSION`） |
| python3 | 打包 / 签名 `scripts/sign.py` |
| zip / 7z | 打包 |

vendored C 依赖：`PLTI`（Android PLT hook）、`CSOLoader`（自定义 linker，绕过 linker 检测）。

## 构建

```bash
export ANDROID_HOME=~/Android/Sdk   # 指向本机 SDK
make all       # debug + release，产物落在 build/out/
make release   # 仅 release
make debug     # 仅 debug
```

产物：`build/out/CaremeZygisk-<versionName>-<versionCode>-<hash>-<type>.zip`，仅含 `armeabi-v7a`。
CI（GitHub Actions）在 push / PR / tag 上自动 `make all` 并上传 artifact，`v*` tag 直接发 release。

## 安装

1. 选包：日常用 `release`，排障用 `debug`（日志更全，仅用于排障 / 提 Issue）。
2. 用 root 管理器（Magisk / KernelSU / APatch）刷入 zip，检查安装日志无误后重启。
3. **Magisk 用户务必关闭内置 Zygisk**（设置里关掉 Zygisk 选项），否则冲突。
4. 重启后在模块描述里确认 daemon 是否在跑。

## 状态

设备专用，持续迭代。针对具体固件的厂商检测适配（Zygote JNI 签名、ArtMethod 布局、anti-ptrace、`native.bridge` 属性检测、maps 扫描、`app_process32` 结构）按机型确认后启用。

## 致谢与许可

基于 PerformanC 的 [ReZygisk](https://github.com/PerformanC/ReZygisk)。遵循 [AGPL 3.0](./LICENSE)。
