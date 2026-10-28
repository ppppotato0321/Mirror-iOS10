# Mirror for iOS 10

前置摄像头自拍镜像插件 — 移植自 BigBoss 源的 **Mirror** (by 0ldGold)

## 原插件信息

- **包名**: `com.ial2wi.mirror`
- **作者**: 0ldGold (@ial2wi)
- **原版本**: 0.0.1-1
- **原支持**: iOS 11 - 13
- **功能**: 让前置摄像头拍出来的照片保持镜像效果（和预览一致）

## 为什么需要移植

原插件只支持 iOS 11+，因为它 hook 的是 iOS 11 重构后的相机类（CAM* 系列）。
iOS 10 及更早版本用的是旧的 PLCamera* 类体系，所以原插件在 iOS 10 上不工作。

## 本版本改动

- 将 hook 点适配为 iOS 10 的 `PLCameraView` / `PLCamera` / `PLCameraPhoto` 类
- 部署目标改为 iOS 10.0
- 保留原插件的偏好设置域名 `com.ial2wi.mirror`

## 项目结构

```
Mirror-iOS10/
├── Makefile              # Theos 编译配置
├── control               # deb 包控制文件
├── Tweak.xm              # 核心源码
└── layout/
    └── Library/
        └── MobileSubstrate/
            └── DynamicLibraries/
                └── Mirror.plist   # Tweak 加载过滤（仅 Camera.app）
```

## 编译方法

### 前提条件
- 已安装 Theos 环境（macOS / Linux / Windows WSL）
- 已配置 iOS 10 SDK

### 编译命令
```bash
cd Mirror-iOS10
make package
```

编译产物在 `packages/` 目录下。

## 安装方法

将编译好的 deb 包传到 iOS 10 越狱设备上，用 Cydia 或 dpkg 安装：
```bash
dpkg -i com.ial2wi.mirror_0.0.1-1~ios10_iphoneos-arm.deb
```

安装后重启 SpringBoard：
```bash
killall SpringBoard
```

## 调试说明

由于不同 iOS 10 小版本（10.0 / 10.1 / 10.2 / 10.3）的相机私有 API 可能有差异，
如果安装后不生效，请按以下步骤调试：

1. 打开设备的 SSH 连接
2. 打开 Console.app 或用 `idevicesyslog` 查看日志
3. 搜索 `[Mirror]` 开头的日志
4. 根据日志判断哪个 hook 点被触发了

### 可能需要调整的地方

如果 `prepareImageForRelease:` 方法不存在或行为不对，可以尝试：
- 检查 `PLCameraView` 的其他拍照完成方法
- 检查 `PLCameraPhoto` 的 `image` 属性
- 检查 `CAMManager` 相关类

## 工作原理

iOS 默认行为：
- 前置摄像头预览：镜像（和镜子里一样）
- 保存的照片：自动翻转成不镜像（别人看到的你）

本插件的作用：
- Hook 照片保存前的处理流程
- 检测是否是前置摄像头拍摄
- 如果是，将照片再水平翻转一次，抵消系统的自动翻转
- 最终效果：保存的照片和预览一致（镜像效果）

## 偏好设置

- 域名: `com.ial2wi.mirror`
- 键: `MirrorEnabled` (BOOL)
- 默认值: YES

可以通过设置 app 的 Tweak 面板切换开关（如果安装了 preferenceloader）。

## 已知限制

- 仅支持 iOS 10.x
- 仅测试前置摄像头拍照，视频录制可能需要额外适配
- 不同设备型号（iPhone 5s / 6 / 6s 等）可能需要微调
