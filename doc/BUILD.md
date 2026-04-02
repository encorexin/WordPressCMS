# 多平台构建指南

本文档介绍如何将 WordPress CMS 构建到不同平台。

## 目录

- [Web 应用](#web-应用)
- [浏览器扩展](#浏览器扩展)
- [Android APK](#android-apk)
- [HarmonyOS HAP](#harmonyos-hap)

---

## Web 应用

### 开发模式

```bash
pnpm dev
```

访问 http://localhost:5173

### 生产构建

```bash
pnpm build
```

输出目录：`dist/`

### 预览构建结果

```bash
pnpm preview
```

---

## 浏览器扩展

### 构建扩展

```bash
pnpm build:extension
```

输出目录：`extension-build/`

### 输出文件

| 文件 | 说明 |
|------|------|
| `wp-cms-helper-chrome.zip` | Chrome 扩展包 |
| `wp-cms-helper-firefox.zip` | Firefox 扩展包 |
| `wp-cms-helper-edge.zip` | Edge 扩展包 |

### 安装方法

#### Chrome

1. 打开 `chrome://extensions/`
2. 开启「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择 `extension-build/chrome` 目录

#### Firefox

1. 打开 `about:debugging`
2. 点击「此 Firefox」
3. 点击「加载临时附加组件」
4. 选择 `extension-build/firefox` 目录中的任意文件

#### Edge

1. 打开 `edge://extensions/`
2. 开启「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择 `extension-build/edge` 目录

---

## Android APK

### 前置要求

- Android Studio
- Android SDK (API 33+)
- JDK 17+

### 构建 Debug APK

```bash
# 构建 Web 应用并同步
pnpm build:apk

# 或使用 Gradle 直接构建
cd android
./gradlew assembleDebug
```

### 构建 Release APK

```bash
cd android
./gradlew assembleRelease
```

### APK 输出位置

| 类型 | 路径 |
|------|------|
| Debug | `android/app/build/outputs/apk/debug/app-debug.apk` |
| Release | `android/app/build/outputs/apk/release/app-release.apk` |

### 签名配置

签名密钥文件位于：`android/app/wpcms-release.keystore`

| 项目 | 值 |
|------|-----|
| 别名 | wpcms |
| 密码 | wpcms2024 |
| 有效期 | 25 年 |

**⚠️ 重要：发布前请修改默认密码并备份密钥文件！**

### 构建 AAB (上架 Google Play)

```bash
cd android
./gradlew bundleRelease
```

输出：`android/app/build/outputs/bundle/release/app-release.aab`

---

## HarmonyOS HAP

### 前置要求

- DevEco Studio 6.0+
- HarmonyOS SDK API 20+

### 同步 Web 资源

```bash
pnpm build:hap
```

### 使用 DevEco Studio 构建

1. 用 DevEco Studio 打开 `harmonyos` 目录
2. 等待项目同步完成
3. 配置签名：
   - **File → Project Structure → Signing Configs**
   - 勾选 **Automatically generate signature**
4. 构建 HAP：
   - **Build → Build Hap(s)/APP(s) → Build Hap(s)**

### 使用命令行构建

```bash
cd harmonyos

# Debug HAP
hvigorw assembleHap

# Release HAP
hvigorw assembleHap --mode release
```

### HAP 输出位置

```
harmonyos/entry/build/default/outputs/default/entry-default-*.hap
```

### 构建 APP (上架华为应用市场)

```bash
cd harmonyos
hvigorw assembleApp --mode release
```

输出：`harmonyos/entry/build/default/outputs/default/entry-default-*.app`

---

## 快速命令参考

| 命令 | 说明 |
|------|------|
| `pnpm dev` | 启动开发服务器 |
| `pnpm build` | 构建 Web 应用 |
| `pnpm build:extension` | 构建浏览器扩展 |
| `pnpm build:apk` | 构建 Android APK |
| `pnpm build:hap` | 构建 HarmonyOS HAP |
| `pnpm cap:sync` | 同步 Capacitor 资源 |
| `pnpm cap:open` | 打开 Android Studio |
| `pnpm sync:harmonyos` | 同步 HarmonyOS 资源 |

---

## 发布检查清单

### Web 应用

- [ ] 更新版本号 (`package.json`)
- [ ] 运行 `pnpm build`
- [ ] 测试构建结果

### 浏览器扩展

- [ ] 更新 `extension/manifest.json` 版本号
- [ ] 准备扩展图标 (128x128)
- [ ] 运行 `pnpm build:extension`
- [ ] 在各浏览器测试

### Android APK

- [ ] 更新版本号 (`android/app/build.gradle`)
- [ ] 配置正式签名密钥
- [ ] 运行 `./gradlew assembleRelease`
- [ ] 测试 APK 安装和运行

### HarmonyOS HAP

- [ ] 更新版本号 (`harmonyos/AppScope/app.json5`)
- [ ] 配置正式签名
- [ ] 构建 Release HAP
- [ ] 在真机测试
