
<div align="center">
<h1>WordPress 内容管理系统</h1>

![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![React](https://img.shields.io/badge/React-18-61dafb.svg)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178c6.svg)
![HarmonyOS](https://img.shields.io/badge/HarmonyOS-ArkTS-red.svg)

**AI 驱动的 WordPress 内容管理系统，支持 Web、HarmonyOS 原生、浏览器扩展、Android 多平台**

[功能特性](#功能特性) · [快速开始](#快速开始) · [多平台支持](#多平台支持) · [项目结构](#项目结构) · [文档](#文档)

</div>

---

## 功能特性

- **AI 智能生成** — 集成 OpenAI、DeepSeek、阿里云百炼等，流式输出实时预览
- **AI 配图** — 自动为文章生成配图，支持多种图片 AI 服务
- **多站点管理** — 集中管理多个 WordPress 站点，一键发布
- **文章模板** — 预置 + 自定义模板，快速生成不同类型文章
- **关键词管理** — 分组管理关键词，批量导入导出
- **主题库** — 管理文章主题，按分类组织
- **Markdown 编辑器** — 工具栏 + 实时预览（HarmonyOS 原生端）
- **数据管理** — 备份导出、加密导出、文件导入恢复
- **版本历史** — 文章修改记录与版本回滚
- **深色模式** — 浅色 / 深色 / 跟随系统
- **本地存储** — 数据存储在本地，不上传服务器
- **浏览器扩展** — Chrome / Firefox / Edge 扩展，侧边栏快速访问

---

## 快速开始

### 环境要求

- Node.js 18+
- pnpm（推荐）

### 安装与运行

```bash
git clone https://github.com/encorexin/WordPressCMS.git
cd WordPressCMS
pnpm install
pnpm dev
```

打开 http://localhost:5173，首次注册的用户自动成为管理员。

### 首次使用

1. **注册账号** — 首页注册，第一个用户为管理员
2. **配置 AI** — 进入 AI 设置，填写 API 端点和密钥
3. **添加站点** — 在站点管理添加 WordPress 站点 URL、用户名、应用密码
4. **生成文章** — 新建文章，输入关键词，选择模板，AI 生成并发布

---

## 多平台支持

| 平台 | 技术栈 | 构建命令 | 输出 |
|------|--------|---------|------|
| Web 应用 | React 18 + TypeScript + Vite + Tailwind | `pnpm build` | `dist/` |
| HarmonyOS 原生 | ArkTS + ArkUI + RDB | DevEco Studio / `hvigorw` | `.hap` |
| 浏览器扩展 | Manifest V3 + Service Worker | `pnpm build:extension` | `extension-build/` |
| Android | Capacitor + WebView | `pnpm build:apk` | `.apk` |

### HarmonyOS 原生端

HarmonyOS 端为**完全原生 ArkTS 应用**（非 WebView），使用 ArkUI 声明式 UI + RDB 本地数据库，功能与 Web 端对齐：

- 仪表板（实时统计）、文章管理、站点管理、设置
- AI 流式生成（SSE）+ Markdown 编辑器 + AI 配图
- 模板库、关键词库、主题库
- 数据备份导出 / 加密导出 / 文件导入
- 用户管理、关于页面

构建方式详见 [BUILD.md](./doc/BUILD.md)。

邀请测试链接：https://appgallery.huawei.com/link/invite-test-wap?taskId=a863a9b39dc9a5c3b89e61b2706b29ed&invitationCode=AOp0X40apUL
---

## 项目结构

```
WordPressCMS/
├── src/                     # Web 应用源码 (React + TypeScript)
│   ├── components/          # 可复用组件
│   ├── context/             # React Context (认证、主题)
│   ├── db/                  # 数据层 (Dexie.js + IndexedDB)
│   ├── pages/               # 页面组件
│   ├── utils/               # 工具函数 (AI、WordPress API、加密)
│   └── types/               # TypeScript 类型
├── harmonyos/               # HarmonyOS 原生应用 (ArkTS)
│   └── entry/src/main/ets/
│       ├── pages/           # 页面 (Dashboard, Articles, Editor, Settings...)
│       ├── services/        # 服务层 (DB, HTTP, Crypto, Auth)
│       ├── models/          # 数据模型
│       ├── components/      # 可复用组件
│       ├── constants/       # 设计 Token、路由、数据库 Schema
│       └── utils/           # 工具 (SSE 解析、日志、日期)
├── extension/               # 浏览器扩展
├── android/                 # Android (Capacitor)
├── doc/                     # 项目文档
├── scripts/                 # 构建脚本
└── package.json
```

---

## 技术架构

### Web 端

| 类别 | 技术 |
|------|------|
| 框架 | React 18 + TypeScript 5 |
| 构建 | Vite 5 |
| 样式 | Tailwind CSS 3 |
| UI 组件 | Radix UI |
| 富文本 | TipTap |
| 数据存储 | Dexie.js (IndexedDB) |
| HTTP | ky |
| AI 流式 | eventsource-parser + streamdown |
| 加密 | Web Crypto API (AES-GCM + PBKDF2) |

### HarmonyOS 端

| 类别 | 技术 |
|------|------|
| 语言 | ArkTS |
| UI | ArkUI 声明式 |
| 数据库 | @ohos.data.relationalStore (RDB/SQLite) |
| HTTP | @ohos.net.http (支持流式) |
| 加密 | @ohos.security.cryptoFramework + HUKS |
| 导航 | Navigation + NavPathStack |
| 状态 | AppStorage + @State/@Link 装饰器 |
| 主题 | WithTheme + 资源限定符 |

---

## 文档

| 文档 | 说明 |
|------|------|
| [BUILD.md](./doc/BUILD.md) | 多平台构建指南 (Web / 扩展 / Android / HarmonyOS) |
| [DEPLOY.md](./doc/DEPLOY.md) | Web 应用部署指南 (Nginx / Vercel / Docker) |
| [EXTENSION.md](./doc/EXTENSION.md) | 浏览器扩展开发和使用指南 |
| [HARMONYOS_NATIVE.md](./doc/HARMONYOS_NATIVE.md) | HarmonyOS 原生应用架构文档 |

---

## 开发命令

```bash
pnpm dev              # 启动 Web 开发服务器
pnpm build            # 构建 Web 生产版本
pnpm preview          # 预览构建结果
pnpm build:extension  # 构建浏览器扩展
pnpm build:apk        # 构建 Android APK
```

---

## 许可证

[MIT](LICENSE)

---

<div align="center">

**Made with ❤️ by [encorexin](https://github.com/encorexin)**

</div>
