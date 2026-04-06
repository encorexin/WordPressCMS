# HarmonyOS 原生 ArkTS 应用架构方案

> WordPress CMS — 原生 ArkUI 应用  
> SDK: HarmonyOS / API 20 (compileSdkVersion 20)  
> 语言: ArkTS (声明式 UI)

---

## 一、设计原则

### 1.1 HarmonyOS Design 核心哲学

- **自然无感**：符合物理世界运动规律，重力、惯性、弹性
- **多设备自适应**：一次开发，多端部署（手机/平板/车机）
- **轻量高效**：服务卡片直达核心功能
- **空间层级**：通过阴影、模糊、透明度构建 Z 轴深度

### 1.2 色彩系统

| 色彩名称 | 色值 | 使用场景 |
|---------|------|---------|
| 鸿蒙蓝 | `#007DFF` | 主按钮、强调色、交互状态 |
| 深邃黑 | `#000000` / `#121212` | 深色模式背景 |
| 纯净白 | `#FFFFFF` | 浅色模式背景、卡片底色 |
| 层级灰 | `#F2F3F5` / `#E4E5E7` | 分隔背景、次级区域 |
| 成功绿 | `#00B578` | 成功状态 |
| 警示橙 | `#FF8800` | 警告状态 |
| 错误红 | `#FA2C2C` | 错误状态 |

### 1.3 字体规范

使用 HarmonyOS Sans 字体家族：

| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| 大标题 | 24-32fp | Bold (700) | 页面标题、重要数据 |
| 小标题 | 18-20fp | Medium (600) | 卡片标题、分区头 |
| 正文 | 14-16fp | Regular (400) | 主要内容、描述文字 |
| 辅助文 | 12fp | Regular (400) | 时间戳、次要信息 |
| 标签文 | 10-11fp | Medium (500) | 角标、状态标签 |

行高比例：1.4-1.6 倍字号

### 1.4 间距与布局

- 基础单位：4vp / 8vp 网格系统
- 安全边距：左右 16vp（手机端）
- 卡片间距：12vp / 16vp / 24vp 三档

### 1.5 圆角规范

| 尺寸 | 值 | 使用场景 |
|------|-----|---------|
| sm | 8vp | 小组件、标签 |
| md | 12vp | 输入框、列表项 |
| lg | 16vp | 卡片 |
| xl | 20vp | 大卡片、底部弹窗 |
| full | 9999vp | 圆形头像、药丸按钮 |

### 1.6 响应式断点

| 断点 | 宽度范围 | 设备类型 | 布局特点 |
|------|---------|---------|---------|
| sm | < 600vp | 手机 | 单列，底部 Tab |
| md | 600-840vp | 折叠屏/小平板 | 双栏 |
| lg | > 840vp | 大平板/PC | 侧边栏 + 多列 |

### 1.7 动效规范

| 场景 | 曲线 | 时长 |
|------|------|------|
| 页面转场 | `Curve.EaseOut` | 300-400ms |
| 弹性回弹 | `curves.springMotion(0.6, 0.9)` | 500ms |
| 手势跟随 | 线性 | 实时 |
| 微交互 | `Curve.EaseInOut` | 150-200ms |

### 1.8 按钮规范

**主按钮 (Filled)**：
- 背景：`#007DFF`
- 圆角：20vp（大）/ 16vp（中）/ 12vp（小）
- 高度：48vp（标准）/ 40vp（紧凑）
- 阴影：`0 4px 12px rgba(0,125,255,0.3)`

**次级按钮 (Outlined)**：
- 边框：1px `#E4E5E7`
- 背景：透明

**输入框**：
- 高度：48vp
- 圆角：12vp
- 背景：`#F2F3F5`（填充式）
- 聚焦：蓝色边框

**列表单元格**：
- 高度：56-72vp
- 左侧图标：24×24vp
- 右侧箭头：16vp，颜色 `#B6B7B9`
- 分隔线：0.5vp，`#E4E5E7`，左侧缩进 56vp

---

## 二、项目目录结构

```
harmonyos/entry/src/main/
├── ets/
│   ├── entryability/
│   │   └── EntryAbility.ets                 # 应用入口，主题初始化，全局配置
│   │
│   ├── pages/                                # 页面层
│   │   ├── Index.ets                         # 主框架 (Navigation + Tab)
│   │   ├── LoginPage.ets                     # 登录/注册
│   │   ├── DashboardPage.ets                 # 仪表板
│   │   ├── SitesPage.ets                     # 站点管理
│   │   ├── ArticlesPage.ets                  # 文章列表
│   │   ├── ArticleEditorPage.ets             # 文章编辑器
│   │   ├── TopicsPage.ets                    # 主题库
│   │   ├── TemplatesPage.ets                 # 模板库
│   │   ├── KeywordsPage.ets                  # 关键词库
│   │   ├── AISettingsPage.ets                # AI 设置
│   │   ├── DataManagementPage.ets            # 数据管理
│   │   ├── AdminPage.ets                     # 管理员
│   │   └── AboutPage.ets                     # 关于页面
│   │
│   ├── components/                           # 可复用组件
│   │   ├── common/
│   │   │   ├── AppNavigation.ets             # 全局导航
│   │   │   ├── SearchBar.ets                 # 全局搜索
│   │   │   ├── EmptyState.ets                # 空状态占位
│   │   │   ├── LoadingOverlay.ets            # 加载遮罩
│   │   │   ├── ConfirmDialog.ets             # 确认对话框
│   │   │   └── StatusBadge.ets               # 状态标签
│   │   ├── article/
│   │   │   ├── ArticleCard.ets               # 文章卡片
│   │   │   ├── AIGenerationPanel.ets         # AI 生成面板
│   │   │   ├── PublishPanel.ets              # WordPress 发布面板
│   │   │   ├── VersionHistorySheet.ets       # 版本历史半模态
│   │   │   └── CategoryPicker.ets            # 分类选择器
│   │   ├── site/
│   │   │   ├── SiteCard.ets                  # 站点卡片
│   │   │   └── SiteFormDialog.ets            # 站点编辑对话框
│   │   ├── template/
│   │   │   ├── TemplateCard.ets              # 模板卡片
│   │   │   └── TemplateFormDialog.ets        # 模板编辑
│   │   └── keyword/
│   │       ├── KeywordChip.ets               # 关键词标签
│   │       └── KeywordGroupList.ets          # 关键词分组列表
│   │
│   ├── services/                             # 业务服务层
│   │   ├── db/
│   │   │   ├── DatabaseHelper.ets            # RDB 初始化 + 版本迁移
│   │   │   ├── UserDao.ets                   # 用户表 CRUD
│   │   │   ├── SiteDao.ets                   # 站点表 CRUD
│   │   │   ├── ArticleDao.ets                # 文章表 CRUD
│   │   │   ├── AISettingsDao.ets             # AI 设置表 CRUD
│   │   │   ├── TemplateDao.ets               # 模板表 CRUD
│   │   │   ├── KeywordDao.ets                # 关键词表 CRUD
│   │   │   ├── TopicDao.ets                  # 主题表 CRUD
│   │   │   └── VersionDao.ets                # 版本表 CRUD
│   │   ├── http/
│   │   │   ├── HttpClient.ets                # 通用 HTTP 封装
│   │   │   ├── WordPressApi.ets              # WordPress REST API
│   │   │   └── AIStreamClient.ets            # AI 流式请求
│   │   ├── crypto/
│   │   │   └── CryptoService.ets             # AES-GCM + PBKDF2 加密服务
│   │   └── auth/
│   │       └── AuthService.ets               # 本地认证
│   │
│   ├── models/                               # 数据模型
│   │   ├── User.ets
│   │   ├── WordPressSite.ets
│   │   ├── Article.ets
│   │   ├── AISettings.ets
│   │   ├── ArticleTemplate.ets
│   │   ├── Keyword.ets
│   │   ├── Topic.ets
│   │   └── ArticleVersion.ets
│   │
│   ├── stores/                               # 状态管理
│   │   ├── AuthStore.ets                     # 登录态 + 用户信息
│   │   ├── ThemeStore.ets                    # 主题状态
│   │   └── AppStore.ets                      # 全局状态初始化
│   │
│   ├── constants/
│   │   ├── DesignTokens.ets                  # 色彩/字体/间距/圆角 Token
│   │   ├── Routes.ets                        # 路由名称常量
│   │   └── DatabaseSchema.ets                # 建表 SQL + 版本号
│   │
│   └── utils/
│       ├── SSEParser.ets                     # SSE 事件流解析器
│       ├── IdGenerator.ets                   # UUID 生成
│       ├── DateUtil.ets                      # 日期格式化
│       ├── Sanitizer.ets                     # 输入过滤
│       └── Logger.ets                        # 分级日志
│
├── resources/
│   ├── base/
│   │   ├── element/
│   │   │   ├── color.json                    # 浅色模式颜色
│   │   │   ├── float.json                    # 尺寸/间距
│   │   │   └── string.json                   # 中文字符串
│   │   ├── media/                            # 图标/图片
│   │   └── profile/
│   │       └── main_pages.json               # 页面路由注册
│   ├── dark/
│   │   └── element/
│   │       └── color.json                    # 深色模式颜色覆盖
│   └── en/
│       └── element/
│           └── string.json                   # 英文字符串 (可选)
│
└── module.json5                              # 模块配置 + 权限声明
```

---

## 三、导航架构

采用 `Navigation` 组件 + `NavPathStack`（官方推荐），手机端底部 Tab 布局，平板端侧边栏布局。

### 3.1 Tab 结构

| Tab | 图标 | 页面 | 说明 |
|-----|------|------|------|
| 0 | ic_dashboard | DashboardPage | 仪表板 |
| 1 | ic_article | ArticlesPage | 文章列表 |
| 2 | ic_site | SitesPage | 站点管理 |
| 3 | ic_settings | SettingsPage | 设置入口 |

### 3.2 页面路由映射

| React 路由 | ArkTS 路由名 | 进入方式 | 说明 |
|------------|-------------|---------|------|
| `/login` | `LoginPage` | 独立页面 | 未登录时展示 |
| `/dashboard` | Tab 0 | 底部 Tab | 仪表板 |
| `/articles` | Tab 1 | 底部 Tab | 文章列表 |
| `/articles/:id` | `ArticleEditorPage` | `pathStack.pushPath` | 编辑器 |
| `/sites` | Tab 2 | 底部 Tab | 站点管理 |
| `/topics` | `TopicsPage` | `pathStack.pushPath` | 设置入口进入 |
| `/templates` | `TemplatesPage` | `pathStack.pushPath` | 设置入口进入 |
| `/keywords` | `KeywordsPage` | `pathStack.pushPath` | 设置入口进入 |
| `/ai-settings` | `AISettingsPage` | `pathStack.pushPath` | 设置入口进入 |
| `/data` | `DataManagementPage` | `pathStack.pushPath` | 设置入口进入 |
| `/admin` | `AdminPage` | `pathStack.pushPath` | 设置入口进入 |
| `/about` | `AboutPage` | `pathStack.pushPath` | 设置入口进入 |

### 3.3 设置页菜单项

设置页作为第 4 个 Tab，展示以下菜单列表：

- 主题库 → TopicsPage
- 模板库 → TemplatesPage
- 关键词库 → KeywordsPage
- AI 设置 → AISettingsPage
- 数据管理 → DataManagementPage
- 管理员 → AdminPage (仅 admin 角色可见)
- 主题切换 → 浅色/深色/跟随系统
- 关于 → AboutPage（应用信息、功能介绍、技术栈、作者信息、开源许可证）

---

## 四、数据层

### 4.1 数据库方案

使用 `@ohos.data.relationalStore` (RDB)，SQLite 底层。

**数据库名**：`WordPressCMS.db`  
**当前版本**：1

### 4.2 表结构 (8 张表)

#### users
```sql
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created_at TEXT NOT NULL
);
```

#### wordpress_sites
```sql
CREATE TABLE IF NOT EXISTS wordpress_sites (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  site_name TEXT NOT NULL,
  site_url TEXT NOT NULL,
  username TEXT NOT NULL,
  app_password TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### articles
```sql
CREATE TABLE IF NOT EXISTS articles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  site_id TEXT,
  title TEXT NOT NULL,
  content TEXT,
  keywords TEXT,
  template TEXT,
  status TEXT DEFAULT 'draft',
  wordpress_post_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### ai_settings
```sql
CREATE TABLE IF NOT EXISTS ai_settings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  is_default INTEGER DEFAULT 0,
  api_endpoint TEXT,
  api_key TEXT,
  model TEXT,
  system_prompt TEXT,
  image_provider TEXT,
  image_api_key TEXT,
  image_endpoint TEXT,
  image_model TEXT,
  image_enabled INTEGER DEFAULT 0,
  slug_model TEXT,
  slug_enabled INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### article_templates
```sql
CREATE TABLE IF NOT EXISTS article_templates (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  system_prompt TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### keywords
```sql
CREATE TABLE IF NOT EXISTS keywords (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  keyword TEXT NOT NULL,
  group_name TEXT,
  use_count INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);
```

#### topics
```sql
CREATE TABLE IF NOT EXISTS topics (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  keywords TEXT,
  category TEXT,
  used INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);
```

#### article_versions
```sql
CREATE TABLE IF NOT EXISTS article_versions (
  id TEXT PRIMARY KEY,
  article_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  title TEXT,
  content TEXT,
  keywords TEXT,
  template TEXT,
  version_number INTEGER NOT NULL,
  created_at TEXT NOT NULL
);
```

### 4.3 加密策略

| 数据类型 | 加密方式 | 说明 |
|---------|---------|------|
| 数据库整体 | RDB `encrypt: true` | 可选，整库加密 |
| `api_key` | 字段级 AES-GCM | `CryptoService` 加解密 |
| `app_password` | 字段级 AES-GCM | `CryptoService` 加解密 |
| 用户密码 | PBKDF2 + SHA-256 哈希 | 单向存储，不可逆 |
| 密钥存储 | HUKS | 派生密钥存入 HUKS 安全容器 |

---

## 五、网络层

### 5.1 HTTP 客户端

模块：`@ohos.net.http` (来自 `@kit.NetworkKit`)

| 方法 | 用途 |
|------|------|
| `request()` | 普通请求，返回完整响应 |
| `requestInStream()` | 流式请求，配合事件监听 |

### 5.2 WordPress REST API

基础 URL：`{site_url}/wp-json/wp/v2`  
认证：`Basic base64(username:app_password)`

| 接口 | 方法 | 路径 | 用途 |
|------|------|------|------|
| 测试连接 | GET | `/users/me` | 验证站点配置 |
| 获取分类 | GET | `/categories?per_page=100` | 获取分类列表 |
| 发布文章 | POST | `/posts` | 创建文章 |
| 更新文章 | POST | `/posts/{id}` | 更新已发布文章 |

### 5.3 AI 流式请求 (SSE)

使用 `requestInStream()` + `on('dataReceive')` 事件实现 SSE 解析：

1. 发起 POST 请求到 AI API 端点
2. 监听 `dataReceive` 事件接收数据块
3. 用自定义 `SSEParser` 解析 `data:` 行
4. 解析 JSON，提取 `choices[0].delta.content`
5. 累积内容，通过回调更新 UI

---

## 六、状态管理

### 6.1 装饰器选型

| 装饰器 | 用途 |
|--------|------|
| `@State` | 组件内私有状态 |
| `@Prop` | 父→子单向传值 |
| `@Link` | 父↔子双向绑定 |
| `@StorageLink` | AppStorage 双向绑定 |
| `@StorageProp` | AppStorage 单向读取 |
| `@Provide` / `@Consume` | 跨层级传递 (导航栈) |
| `@Observed` / `@ObjectLink` | 嵌套对象观察 |

### 6.2 全局状态 (AppStorage)

| Key | 类型 | 说明 |
|-----|------|------|
| `isLoggedIn` | boolean | 登录状态 |
| `currentUserId` | string | 当前用户 ID |
| `currentUserRole` | string | 用户角色 |
| `themeMode` | string | 主题模式 (light/dark/system) |
| `currentBreakpoint` | string | 当前断点 (sm/md/lg) |

---

## 七、主题系统

### 7.1 实现方案

- 根组件使用 `WithTheme({ colorMode })` 包裹
- 资源文件 `resources/dark/element/color.json` 覆盖深色色值
- 通过 `AppStorage` 存储用户偏好
- 监听 `onConfigurationUpdate` 响应系统主题变化

### 7.2 主题切换

```
用户选择 → AppStorage.set('themeMode', mode) → WithTheme 响应 → UI 自动更新
```

---

## 八、已实现功能

### 核心功能 (P0)

| # | 功能 | 状态 |
|---|------|------|
| 1 | 项目骨架 — 导航框架 + 主题 + 数据库初始化 | ✅ |
| 2 | 本地认证 — 注册/登录 + Session 管理 | ✅ |
| 3 | 站点管理 — 添加/编辑/删除站点 + 连接测试 | ✅ |
| 4 | 文章列表 — 列表展示 + 搜索过滤 + 状态管理 | ✅ |
| 5 | 文章编辑器 — Markdown 编辑器 + AI 流式生成 + 发布 | ✅ |
| 6 | AI 流式生成 — SSE 解析 + 流式 UI 更新 | ✅ |

### 重要功能 (P1)

| # | 功能 | 状态 |
|---|------|------|
| 7 | 数据加密 — AES-GCM + PBKDF2 + HUKS | ✅ |
| 8 | AI 设置 — 多 Provider 配置管理 | ✅ |
| 9 | 模板管理 — CRUD + 系统提示词编辑 | ✅ |
| 10 | 关键词管理 — 分组展示 + 使用统计 | ✅ |
| 11 | 主题库 — 主题 CRUD + 使用标记 | ✅ |
| 12 | 深色模式 — 完整深色主题适配 | ✅ |

### 增强功能 (P2)

| # | 功能 | 状态 |
|---|------|------|
| 13 | 仪表板统计 — 站点/文章数据卡片 + 实时刷新 | ✅ |
| 14 | 版本历史 — 版本对比 + 回滚 | ✅ |
| 15 | 数据导入导出 — 文件导出/导入 + 加密导出 | ✅ |
| 16 | AI 配图 — 多 Provider 图片 AI | ✅ |
| 17 | Markdown 编辑器 — 工具栏 + 实时预览 | ✅ |
| 18 | 关于页面 — 应用信息 + 功能列表 + 技术栈 + 作者信息 | ✅ |

---

## 九、技术决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 导航 | `Navigation` + `NavPathStack` | 官方推荐，路由栈管理完善 |
| 数据库 | `relationalStore` (RDB) | 结构化查询，支持加密 |
| HTTP | `@ohos.net.http` | 原生模块，支持 `requestInStream` 流式 |
| 加密 | `cryptoFramework` + `huks` | AES-GCM + PBKDF2，对标 Web Crypto API |
| 富文本 | Markdown 编辑器 (TextArea + 工具栏 + 实时预览) | 完全自定义，功能丰富 |
| 主题 | `WithTheme` + 资源限定符 | 系统级深浅色自动切换 |
| 响应式 | `GridRow` / `GridCol` | 栅格系统 + 断点监听 |
| 状态 | `AppStorage` + 装饰器 | 轻量，无需三方库 |

---

## 十、权限声明

```json5
{
  "requestPermissions": [
    { "name": "ohos.permission.INTERNET" },
    { "name": "ohos.permission.GET_NETWORK_INFO" }
  ]
}
```

---

## 十一、从 React 到 ArkTS 映射表

| React | ArkTS |
|-------|-------|
| React Router | `Navigation` + `NavPathStack` |
| Context / Redux | `AppStorage` + `@State`/`@Link` |
| localStorage | `@ohos.data.preferences` |
| IndexedDB (Dexie) | `@ohos.data.relationalStore` |
| fetch / ky | `@ohos.net.http` |
| eventsource-parser (SSE) | `requestInStream` + 自定义 `SSEParser` |
| TipTap RichEditor | Markdown 编辑器 (TextArea + 工具栏 + 预览) |
| Tailwind CSS | `@Styles` + 资源引用 `$r()` |
| Radix UI | ArkUI 原生组件 |
| bcryptjs | `@ohos.security.cryptoFramework` PBKDF2 |
| Web Crypto (AES-GCM) | `@ohos.security.cryptoFramework` AES/GCM |
| Sonner Toast | `promptAction.showToast()` |
| Lucide Icons | 系统图标 + 自定义 SVG |
