# Changelog

本文档记录 WordPress CMS 各平台版本更新历史。

---

## WordPressCMS v1.3.0 (2026-04-12)

### HarmonyOS

- **P0 安全与兼容修复** — 修复 `SiteCard` 复用态 `isTesting` 同步问题；为 `wordpress_sites.app_password`、`ai_settings.api_key`、`ai_settings.image_api_key` 引入字段级加密与兼容读取；统一数据导入归一化入口，兼容普通备份与整包加密备份。
- **类型安全与错误处理收口** — 为 WordPress、AI 非流式响应、SSE、图片生成等高风险解析入口补齐显式接口与 helper，减少动态属性访问；统一 `Logger.error / warn / debug` 记录口径，避免静默吞错。
- **设计令牌与深色模式清理** — 新增遮罩、强遮罩、浮层阴影、信息态浅背景、成功态浅背景等资源色，批量替换多处硬编码颜色；修复文章编辑器导出 HTML 在跟随系统主题时的深浅色判断。
- **大文件拆分与模块化** — 完成 `ArticleEditorPage`、`KeywordsPage`、`AISettingsPage`、`TopicsPage`、`ArticlesPage`、`DataManagementPage`、`DashboardPage` 与 `ImageGenerationService` 的首轮拆分，主文件收敛为页面编排 / 服务编排，新增多组 HeaderPanel、ContentSection、Dialog 与 helper 组件。
- **数据与存储基础设施升级** — 新增 `AppStorageKeys`，收口 Theme / Role 关键类型；引入 `BaseDao<T>` 试点；将 HarmonyOS 数据库 schema 升级到 `DB_VERSION = 2`，补齐 schema metadata、显式迁移链与多组高频索引。
- **移动端界面优化** — 新建文章 FAB 改为真正的圆形图标按钮；主题页说明卡与搜索框、文章卡片区横向对齐；文章列表卡片增加摘要与元信息展示空间，底部操作区高度进一步拉长，提升小屏可读性与点击舒适度。

### Web / Extension / Android

- **P0 快速安全修复** — 修复 Dexie 迁移表名不一致问题，移除与 `react-router-dom` 主版本冲突的 `react-router` 直接依赖，并修正 Radix `Dialog` / `AlertDialog` 包装层的 `ref` 转发告警。
- **数据层门面收口** — `src/db/api.ts` 收敛为统一兼容入口，`src/db/database.ts` 的 legacy 职责拆分到 `src/db/legacyDatabase.ts`，站点、模板、关键词、主题、Dashboard 等主要页面优先迁移到统一数据入口；`src/utils/wordpress.ts` 收敛为 `wordpressClient.ts` 的过渡导出层。
- **质量门禁基础设施** — `package.json` 补齐 `lint`、`lint:fix`、`format`、`typecheck`、`test`、`test:coverage`，新增 `tsconfig.check.json`；Web 侧引入 Vitest + React Testing Library 最小测试样例，HarmonyOS 侧补齐 `ohosTest` / Hypium 测试骨架。
- **构建与交付链路增强** — `pnpm typecheck`、`pnpm test`、`pnpm build`、`pnpm build:extension` 已形成可重复执行的基础验证链路；扩展解压产物可稳定生成，Android / Extension / HarmonyOS 对外版本统一提升到 `1.3.0`。

---

## HarmonyOS v1.2.0 (2026-04-08)

### 新功能

- **文章字数统计** — 在文章列表卡片与编辑器内展示字数，并写入数据库字段 `word_count`
- **Token 统计** — 支持文章生成后的 Token 统计（本次/累计），并写入文章字段 `tokens_used`
- **AI 配置 Token 统计** — AI 设置卡片展示该配置累计 Token 使用量，并写入字段 `tokens_used`
- **离线预览** — 预览页改为本地 `rawfile` 资源渲染（marked + highlight.js + 主题 CSS），无网络也可用

### 改进

- **预览支持代码高亮** — 预览页对代码块启用 highlight.js 语法高亮
- **预览跟随主题** — 预览页支持深浅色切换（URL theme 参数 + JS 注入兜底）
- **生成体验优化** — AI 流式生成期间支持自动跟随到底部；用户手动滚动后停止跟随并提供“一键跟随底部”
- **数据库自迁移增强** — 新增 articles/ai_settings 的安全 ALTER，旧数据自动补齐统计字段

### Bug 修复

- **预览 Sheet detents 编译失败** — 移除不存在的 `SheetSize.FULL`
- **预览关闭按钮重叠** — 移除自定义关闭按钮，避免与 Sheet 默认关闭按钮叠加
- **主题枚举判断错误** — 修复 `ColorMode` 深浅色枚举值判断逻辑，预览可正确切换到深色
- **生成中编辑器滚动异常** — 避免 TextArea 高频刷新导致滚动位置重置，生成时改为只读滚动容器

---

## HarmonyOS v1.1.0 (2026-04-07)

### Bug 修复

- **Dashboard 统计数据始终显示 0** — `@Builder` 方法接收基本类型参数（`number`、`boolean`）按值传递，异步更新 `@State` 后 Builder 内部参数副本不刷新。重构为内联直接引用 `@State` 变量 (`DashboardPage.ets`)
- **快速开始步骤完成后不打勾** — 同上根因，`@Builder SetupCheckItem` 的 `completed` 参数不响应变化。改为内联引用 `this.hasSites`、`this.hasAiConfig` 等 `@State` 变量 (`DashboardPage.ets`)
- **主题库选择主题后编辑器不显示已选主题** — `TopicDao.findByUserId(userId, 0)` 只加载未使用主题，已选主题被标记为已使用后从列表消失。改为 `findByUserId(userId, -1)` 加载全部主题 (`ArticleEditorPage.ets`)
- **文章卡片日期溢出到卡片外** — `ArticleMetaRow` 布局中关键词文本未限制宽度，日期被挤出。添加 `layoutWeight(1)` + `flexShrink(0)` 修复 flex 布局 (`ArticlesPage.ets`)
- **数据管理页统计卡片间距不足** — `StatsCard` 内行元素紧贴，添加 `space: Spacing.MD` 间距 (`DataManagementPage.ets`)
- **AuthService.applySession() 写入顺序错误** — 修复 session 恢复时的状态写入顺序 (`AuthService.ets`)
- **登录页缺少本地存储提示** — 添加"数据存储在本地，不上传服务器"提示文本 (`LoginPage.ets`)
- **AI 设置页模型测试不显示返回值** — 测试成功或失败均显示 API 返回内容 (`AISettingsPage.ets`)

### 改进

- 删除所有 `@Builder StatCard` 和 `@Builder SetupCheckItem`，改为内联实现，避免 ArkUI 参数传值陷阱
- Dashboard 统计数据加载流程优化

---

## HarmonyOS v1.0.0 (2026-04-04)

### 新功能

- HarmonyOS 原生 ArkTS 应用完整实现（非 WebView）
- Dashboard 仪表板 — 实时统计卡片、快速开始引导、最近文章
- 文章管理 — 列表、搜索、筛选、删除
- 文章编辑器 — Markdown 工具栏 + 实时预览 + AI 流式生成（SSE）
- AI 配图 — 自动为文章生成配图
- 站点管理 — 添加、编辑、删除 WordPress 站点
- 模板库 — 预置 + 自定义文章模板
- 关键词库 — 分组管理、批量导入导出
- 主题库 — 文章主题分类管理
- AI 设置 — OpenAI / DeepSeek / 阿里云百炼，API 端点 + 密钥配置
- 数据管理 — 备份导出、加密导出、文件导入恢复
- 用户管理 — 注册、登录、多用户隔离
- 关于页面 — 版本信息、技术栈、开源协议
- 深色模式 — 浅色 / 深色 / 跟随系统
- 本地存储 — RDB (SQLite) 数据库，数据不上传服务器

---

## Web v1.2.0 (2026-04-04)

### 新功能

- HarmonyOS 原生应用支持
- 浏览器扩展 (Chrome / Firefox / Edge)
- Android 应用 (Capacitor)
- AI 配图功能
- 主题库管理
- 数据管理（备份、加密导出、导入恢复）
- Markdown 编辑器实时预览
- 深色模式
