# Changelog

本文档记录 WordPress CMS 各平台版本更新历史。

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
