# WordPress 内容管理系统

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![React](https://img.shields.io/badge/React-18-61dafb.svg)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178c6.svg)

**AI驱动的WordPress内容管理系统，轻松管理多个站点，一键生成高质量文章**

[项目简介](#-项目简介) · [核心功能](#-核心功能) · [使用指南](#-使用指南) · [技术架构](#-技术架构) · [项目结构](#-项目结构) · [安全特性](#-安全特性) · [开发部署](#-开发部署) · [文档](#-文档)

</div>

---

## 📖 项目简介

WordPress 内容管理系统是一个基于 React + TypeScript 开发的现代化内容创作平台，专为 WordPress 站点管理员和内容创作者设计。

### 核心价值

- **AI 驱动**：集成多种 AI 模型，自动生成高质量文章
- **多站点管理**：集中管理多个 WordPress 站点，实现一键发布
- **本地存储**：所有数据存储在本地浏览器，确保数据安全
- **扩展支持**：提供浏览器扩展，方便日常使用
- **高度定制**：支持自定义模板、提示词和 API 配置

### 适用场景

- **内容创作者**：快速生成文章草稿，提高创作效率
- **SEO 优化师**：批量生成关键词相关内容
- **WordPress 站点管理员**：统一管理多个站点的内容发布
- **数字营销人员**：快速创建营销内容

---

## ✨ 核心功能

### 🤖 AI 智能生成

**功能详情**：
- **多 AI 服务集成**：支持 OpenAI、DeepSeek、阿里云百炼等多种 AI 服务
- **自定义 API 配置**：灵活配置不同 AI 服务的 API 端点和参数
- **系统提示词定制**：完全自定义 AI 生成的风格、格式和内容要求
- **流式输出**：实时预览 AI 生成内容，支持 Markdown 实时渲染
- **模型选择**：支持不同模型的切换，适应不同场景需求

**使用方法**：
1. 进入「AI 设置」页面配置 API 密钥
2. 在文章编辑器中输入关键词
3. 选择合适的模板和模型
4. 点击「AI 生成文章」按钮
5. 实时查看生成过程，可随时停止

### 📑 文章模板库

**功能详情**：
- **预置模板**：包含技术教程、产品评测、SEO 文章、新闻稿等多种模板
- **自定义模板**：创建和管理专属的文章生成模板
- **模板分类**：按类型和用途组织模板
- **一键应用**：在编辑器中快速切换不同模板
- **模板变量**：支持 `{keywords}`、`{template}` 等占位符

**使用方法**：
1. 进入「模板管理」页面
2. 浏览或搜索模板
3. 点击模板查看详情和预览
4. 在文章编辑器中选择模板应用

### 🏷️ 关键词管理

**功能详情**：
- **关键词库**：保存和管理常用关键词
- **分组管理**：按类别和主题组织关键词
- **批量操作**：支持批量导入、导出关键词
- **关键词分析**：查看关键词使用频率和关联文章
- **智能推荐**：基于历史使用推荐相关关键词

**使用方法**：
1. 进入「关键词管理」页面
2. 点击「添加关键词」或「批量导入」
3. 为关键词设置分组和标签
4. 在文章编辑器中选择关键词使用

### 🌐 多站点管理

**功能详情**：
- **统一管理**：集中管理多个 WordPress 站点的连接信息
- **一键发布**：直接从编辑器发布文章到指定站点
- **站点状态**：实时监控站点连接状态和健康度
- **站点分类**：按项目或用途组织站点
- **批量操作**：支持批量测试站点连接

**使用方法**：
1. 进入「站点管理」页面
2. 点击「添加站点」，输入站点 URL、用户名和应用密码
3. 点击「测试连接」验证站点配置
4. 在文章编辑器中选择目标站点发布

### 📝 文章管理

**功能详情**：
- **文章列表**：查看所有文章的状态和详情
- **版本历史**：记录文章的修改历史，支持版本回滚
- **批量操作**：支持批量删除、导出文章
- **搜索过滤**：按标题、状态、关键词等过滤文章
- **状态管理**：草稿、待发布、已发布等状态跟踪

**使用方法**：
1. 进入「文章管理」页面
2. 浏览或搜索文章
3. 点击文章进入编辑页面
4. 使用版本历史查看和恢复历史版本

### 💾 数据管理

**功能详情**：
- **数据备份**：一键导出所有数据为 JSON 文件
- **数据恢复**：从备份文件恢复数据
- **数据清理**：清理无用数据，优化存储空间
- **数据加密**：支持数据加密导出，增强安全性
- **导入导出**：支持与其他系统的数据交换

**使用方法**：
1. 进入「数据管理」页面
2. 选择「导出数据」，可选择是否加密
3. 选择「导入数据」，上传备份文件
4. 查看数据统计和存储使用情况

### 🌙 主题系统

**功能详情**：
- **多主题支持**：浅色、深色、跟随系统
- **自动保存**：记住用户的主题偏好
- **响应式设计**：适配不同屏幕尺寸
- **高对比度模式**：支持无障碍访问

**使用方法**：
1. 点击顶部导航栏的主题切换按钮
2. 选择喜欢的主题模式
3. 系统会自动保存设置

### � 浏览器扩展

**功能详情**：
- **快速访问**：通过浏览器扩展快速打开 CMS
- **侧边栏模式**：在浏览器侧边栏使用 CMS 功能
- **新标签页**：在新标签页中使用完整功能
- **数据同步**：与主应用数据保持同步
- **跨浏览器支持**：支持 Chrome、Firefox、Edge

**使用方法**：
1. 构建并安装扩展（详见 [EXTENSION.md](./doc/EXTENSION.md)）
2. 点击浏览器扩展图标打开
3. 选择使用方式：侧边栏或新标签页

---

## � 使用指南

### 快速开始

#### 环境要求
- Node.js 18+
- npm、yarn 或 pnpm

#### 安装步骤

```bash
# 克隆项目
git clone https://github.com/encorexin/WordPressCMS.git
cd WordPressCMS

# 安装依赖
pnpm install

# 启动开发服务器
pnpm dev
```

打开浏览器访问 `http://localhost:5173`

> 💡 **无需配置环境变量**，所有设置都在应用内完成

### 首次使用流程

#### 1. 账号注册
- 访问登录页面，点击「注册」按钮
- 填写邮箱、密码和用户名
- 第一个注册的用户将自动成为管理员

#### 2. AI 配置
1. 进入「AI 设置」页面
2. **选择 API 端点**：从下拉菜单选择 AI 服务商
3. **输入 API Key**：填写对应服务的 API 密钥
4. **选择模型**：根据需要选择合适的 AI 模型
5. **测试连接**：点击「测试连接」验证配置是否正确
6. **保存设置**：配置成功后保存

#### 3. 添加 WordPress 站点
1. 进入「站点管理」页面
2. 点击「添加站点」按钮
3. **填写站点信息**：
   - 站点名称：自定义标识
   - 站点 URL：WordPress 站点地址（如 https://example.com）
   - 用户名：WordPress 管理员用户名
   - 应用密码：WordPress 应用程序密码
4. **测试连接**：验证站点配置
5. **保存站点**：添加到站点列表

> ℹ️ **WordPress 应用密码生成**：
> 1. 登录 WordPress 后台
> 2. 进入「用户」→「个人资料」
> 3. 滚动到「应用程序密码」部分
> 4. 输入名称（如"CMS"），点击「添加新的应用程序密码」
> 5. 复制生成的密码（只显示一次）

#### 4. 创建和发布文章
1. 进入「文章管理」页面
2. 点击「新建文章」按钮
3. **设置文章信息**：
   - 标题：文章标题
   - 关键词：输入相关关键词
   - 模板：选择合适的文章模板
4. **AI 生成**：点击「AI 生成文章」按钮
5. **编辑内容**：在编辑器中修改和完善内容
6. **选择站点**：从右侧选择目标 WordPress 站点
7. **发布文章**：点击「发布到 WordPress」按钮

### 高级使用技巧

#### AI 提示词优化
- **具体明确**：提供详细的写作要求和风格指导
- **结构化**：使用清晰的层级和格式要求
- **个性化**：根据目标受众调整语言风格
- **示例**：
  ```
  你是一位专业的技术博客作者，擅长撰写深入浅出的技术教程。
  请根据以下关键词创作一篇关于 React Hooks 的文章：{keywords}
  
  要求：
  1. 使用 Markdown 格式，包含标题、小标题、代码示例
  2. 内容结构：介绍、核心概念、使用场景、最佳实践、总结
  3. 代码示例要有详细注释
  4. 面向中级前端开发者
  5. 字数 1500-2000 字
  ```

#### 模板创建技巧
- **分类管理**：按内容类型创建不同模板
- **变量使用**：充分利用 `{keywords}` 和 `{template}` 占位符
- **风格统一**：保持模板风格的一致性
- **定期更新**：根据效果反馈调整模板

#### 多站点管理策略
- **分组管理**：按项目或客户分组站点
- **定期测试**：定期测试站点连接状态
- **批量操作**：利用批量发布功能提高效率
- **站点健康**：监控站点的发布成功率

---

## 🛠 技术架构

### 前端技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 框架 | React | 18 | 用户界面库 |
| 语言 | TypeScript | 5 | 类型安全 |
| 构建工具 | Vite | 5 | 快速构建和热更新 |
| CSS 框架 | Tailwind CSS | 4 | 原子化样式 |
| UI 组件 | Radix UI | 1 | 无障碍组件库 |
| 图标库 | Lucide React | 0.300+ | 现代化图标 |
| 通知系统 | Sonner | 1 | Toast 通知 |

### 数据存储

| 存储方式 | 技术 | 用途 |
|---------|------|------|
| 主要存储 | Dexie.js + IndexedDB | 持久化数据存储 |
| 会话存储 | localStorage | 登录状态和主题设置 |
| 扩展存储 | Chrome Storage | 扩展数据同步 |

### AI 集成

| 技术 | 用途 |
|------|------|
| ky | HTTP 客户端，处理 API 请求 |
| eventsource-parser | SSE 流解析，处理 AI 流式输出 |
| streamdown | Markdown 流式渲染 |
| AES-GCM | 数据加密 |
| PBKDF2 | 密码哈希 |

### 浏览器扩展

| 技术 | 用途 |
|------|------|
| Manifest V3 | 扩展配置 |
| Service Worker | 后台任务和数据同步 |
| Side Panel API | 浏览器侧边栏集成 |
| Chrome Storage API | 跨扩展数据存储 |

---

## 📁 项目结构

```
WordPressCMS/
├── src/                 # 源代码目录
│   ├── components/      # 可复用组件
│   │   ├── common/      # 通用组件
│   │   │   ├── Header.tsx        # 顶部导航栏
│   │   │   ├── Footer.tsx        # 页脚
│   │   │   ├── GlobalSearch.tsx  # 全局搜索
│   │   │   ├── RichTextEditor.tsx # 富文本编辑器
│   │   │   └── ErrorBoundary.tsx  # 错误边界
│   │   └── ui/          # UI 基础组件
│   ├── context/         # React Context
│   │   ├── LocalAuthProvider.tsx  # 本地认证
│   │   └── ThemeProvider.tsx      # 主题管理
│   ├── db/              # 数据层
│   │   ├── database.ts           # 数据库配置
│   │   ├── localAuth.ts          # 认证逻辑
│   │   ├── api.ts                # 数据 CRUD
│   │   ├── aiSettings.ts         # AI 设置
│   │   ├── templateService.ts    # 模板服务
│   │   ├── keywordService.ts     # 关键词服务
│   │   ├── versionService.ts     # 版本历史
│   │   └── dataExport.ts         # 数据导出/导入
│   ├── pages/           # 页面组件
│   │   ├── Landing.tsx           # 首页
│   │   ├── Login.tsx             # 登录/注册
│   │   ├── Dashboard.tsx         # 仪表板
│   │   ├── Sites.tsx             # 站点管理
│   │   ├── Articles.tsx          # 文章列表
│   │   ├── ArticleEditor.tsx     # 文章编辑器
│   │   ├── Templates.tsx         # 模板管理
│   │   ├── Keywords.tsx          # 关键词管理
│   │   ├── AISettings.tsx        # AI 设置
│   │   ├── DataManagement.tsx    # 数据管理
│   │   └── Admin.tsx             # 管理员页面
│   ├── utils/           # 工具函数
│   │   ├── aiChat.ts             # AI 聊天处理
│   │   ├── wordpress.ts          # WordPress API
│   │   ├── crypto.ts             # 加密工具
│   │   └── encryptedStorage.ts   # 加密存储
│   ├── types/           # TypeScript 类型
│   ├── App.tsx          # 应用入口
│   ├── main.tsx         # 主入口
│   └── main.extension.tsx # 扩展入口
├── extension/           # 浏览器扩展
│   ├── icons/           # 扩展图标
│   ├── manifest.json    # 扩展配置
│   ├── background.js    # 后台脚本
│   ├── popup.html       # 弹出窗口
│   └── popup.js         # 弹出窗口脚本
├── doc/                 # 文档目录
├── scripts/             # 构建脚本
├── public/              # 静态资源
├── package.json         # 项目配置
└── README.md            # 项目文档
```

---

## � 安全特性

### 数据安全

- **本地存储**：所有数据存储在浏览器本地 IndexedDB，不上传到任何服务器
- **密码加密**：用户密码使用 bcryptjs 加密后存储
- **API Key 保护**：AI API 密钥和 WordPress 密码加密存储
- **数据加密**：支持导出数据的加密功能
- **会话管理**：基于 localStorage 的安全会话管理

### 安全最佳实践

- **最小权限**：仅请求必要的浏览器权限
- **输入验证**：所有用户输入经过严格验证
- **CSP 策略**：浏览器扩展使用严格的内容安全策略
- **错误处理**：详细的错误处理和日志记录
- **定期备份**：提醒用户定期导出数据备份

---

## � 开发部署

### 开发命令

```bash
# 启动开发服务器
pnpm dev

# 构建生产版本
pnpm build

# 构建扩展版本
pnpm build:extension

# 预览生产构建
pnpm preview
```

### 部署选项

1. **本地部署**：
   - 构建生产版本：`pnpm build`
   - 部署到本地服务器或静态托管服务

2. **浏览器扩展**：
   - 构建扩展：`pnpm build:extension`
   - 加载到浏览器：
     - Chrome/Edge：扩展管理 → 开发者模式 → 加载已解压的扩展
     - Firefox：about:debugging → 加载临时附加组件

3. **容器部署**：
   - 可使用 Nginx 或 Apache 部署静态文件
   - 支持 Docker 容器化部署

### 环境配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `VITE_APP_NAME` | 应用名称 | WordPress CMS |
| `VITE_APP_VERSION` | 应用版本 | 1.0.0 |
| `VITE_API_TIMEOUT` | API 超时时间 | 30000 |
| `VITE_STORAGE_NAME` | 存储名称 | WordPressCMS |

---

## 📚 文档

更多详细文档请查看 [doc](./doc/) 目录：

| 文档 | 说明 |
|------|------|
| [BUILD.md](./doc/BUILD.md) | 多平台构建指南 (Web/扩展/Android/HarmonyOS) |
| [EXTENSION.md](./doc/EXTENSION.md) | 浏览器扩展开发和使用指南 |
| [DEPLOY.md](./doc/DEPLOY.md) | 部署指南 |
| [OPTIMIZATION_ROADMAP.md](./doc/OPTIMIZATION_ROADMAP.md) | 项目优化路线图 |

---

## 🚀 多平台支持

本项目支持构建到多个平台：

| 平台 | 构建命令 | 输出 |
|------|---------|------|
| Web 应用 | `pnpm build` | `dist/` |
| 浏览器扩展 | `pnpm build:extension` | `extension-build/` |
| Android APK | `pnpm build:apk` | `android/app/build/outputs/apk/` |
| HarmonyOS HAP | `pnpm build:hap` | `harmonyos/entry/build/outputs/` |

详细构建说明请查看 [BUILD.md](./doc/BUILD.md)。 |

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. **Fork 本仓库**
2. **创建功能分支**：`git checkout -b feature/amazing-feature`
3. **提交更改**：`git commit -m 'Add amazing feature'`
4. **推送分支**：`git push origin feature/amazing-feature`
5. **提交 Pull Request**

### 开发规范

- **代码风格**：使用 Biome 进行代码格式化
- **类型安全**：确保 TypeScript 类型检查通过
- **测试**：添加必要的测试用例
- **文档**：更新相关文档

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## � 致谢

- **React** - 用于构建用户界面的 JavaScript 库
- **TypeScript** - 类型安全的 JavaScript 超集
- **Tailwind CSS** - 实用优先的 CSS 框架
- **Dexie.js** - IndexedDB 的优雅封装
- **Radix UI** - 无障碍 UI 组件库
- **Lucide** - 美观的开源图标库

---

<div align="center">

**Made with ❤️ by AI-Powered Development**

</div>
