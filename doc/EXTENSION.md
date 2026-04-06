# WordPress CMS 助手 - 浏览器扩展

将 WordPress CMS 助手打包为浏览器扩展，支持 Chrome、Firefox、Edge。

## 功能特性

- 🔐 **数据加密存储** - 本地加密保存所有数据
- 🤖 **AI 文章生成** - 支持多种 AI 模型
- 📤 **一键发布** - 快速发布到 WordPress
- 🎨 **模板管理** - 自定义文章模板
- 📱 **多种模式** - 支持 Popup、Side Panel、新标签页

## 快速开始

### 1. 构建扩展

```bash
# 构建生产版本
pnpm build:extension

# 或
npm run build:extension
```

### 2. 安装扩展

#### Chrome / Edge

1. 打开 `chrome://extensions/` 或 `edge://extensions/`
2. 开启右上角"开发者模式"
3. 点击"加载已解压的扩展程序"
4. 选择 `extension-build/chrome` 或 `extension-build/edge` 目录

#### Firefox

1. 打开 `about:debugging`
2. 点击"此 Firefox"
3. 点击"加载临时附加组件"
4. 选择 `extension-build/firefox/manifest.json`

### 3. 使用扩展

- **点击图标** - 打开快速操作面板，查看统计信息
- **打开侧边栏** - 在侧边栏使用完整功能
- **新标签页** - 在新标签页打开完整应用

## 开发模式

```bash
# 开发模式（支持热更新）
pnpm dev:extension

# 然后手动加载 dist 目录到浏览器
```

## 项目结构

```
extension/
├── manifest.json      # 扩展配置文件
├── popup.html         # 弹出窗口页面
├── popup.js           # 弹出窗口脚本
└── background.js      # 后台 Service Worker

src/
├── main.extension.tsx # 扩展环境入口
└── ...

scripts/
└── build-extension.js # 扩展打包脚本

vite.config.extension.ts # 扩展构建配置
index.extension.html     # 扩展入口 HTML
```

## 技术细节

### 路由适配

扩展环境使用 `HashRouter` 代替 `BrowserRouter`，因为扩展页面不支持标准的历史 API。

```typescript
// 标准环境
<BrowserRouter>
  <App />
</BrowserRouter>

// 扩展环境
<HashRouter>
  <App />
</HashRouter>
```

### 存储机制

- **IndexedDB** - 主数据存储（Dexie.js）
- **Chrome Storage** - 扩展配置和统计数据同步
- **localStorage** - 主题等简单设置

### 数据同步

后台脚本定期将 IndexedDB 数据同步到 Chrome Storage，供弹出窗口使用：

```javascript
// background.js
chrome.alarms.create('updateStats', { periodInMinutes: 60 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'updateStats') {
    updateStatistics();
  }
});
```

### 消息通信

内容脚本、弹出窗口、后台脚本之间通过消息 API 通信：

```javascript
// 发送消息
chrome.runtime.sendMessage({
  type: 'UPDATE_STATS',
  data: { articles: 10, sites: 2 }
});

// 接收消息
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  // 处理消息
});
```

## 浏览器兼容性

| 功能 | Chrome | Firefox | Edge |
|------|--------|---------|------|
| Popup | ✅ | ✅ | ✅ |
| Side Panel | ✅ 114+ | ❌ | ✅ 114+ |
| Service Worker | ✅ | ✅ | ✅ |
| Chrome Storage | ✅ | ✅* | ✅ |

*Firefox 使用 `browser.storage` API

## 自定义配置

### 修改 manifest

编辑 `extension/manifest.json`：

```json
{
  "name": "你的扩展名称",
  "version": "1.0.0",
  "permissions": [
    "storage",
    "activeTab"
  ]
}
```

### 添加图标

将图标文件放入 `extension/icons/`：
- icon16.png (16x16)
- icon32.png (32x32)
- icon48.png (48x48)
- icon128.png (128x128)

### 修改弹出窗口

编辑 `extension/popup.html` 和 `extension/popup.js`

## 发布到商店

### Chrome Web Store

1. 访问 [Chrome Developer Dashboard](https://chrome.google.com/webstore/devconsole/)
2. 支付 $5 开发者注册费
3. 上传 `extension-build/wp-cms-helper-chrome.zip`
4. 填写应用信息并提交审核

### Firefox Add-ons

1. 访问 [Firefox Developer Hub](https://addons.mozilla.org/developers/)
2. 注册开发者账号
3. 上传 `extension-build/wp-cms-helper-firefox.zip`
4. 提交审核

### Edge Add-ons

1. 访问 [Partner Center](https://partner.microsoft.com/dashboard/microsoftedge/overview)
2. 注册开发者账号
3. 上传 `extension-build/wp-cms-helper-edge.zip`
4. 提交审核

## 常见问题

### Q: 扩展无法加载？

A: 检查以下几点：
1. manifest.json 格式是否正确
2. 所有引用的文件是否存在
3. 开发者模式是否开启

### Q: 数据没有同步？

A: 确保：
1. 已登录账号
2. 数据已解密
3. 后台脚本正常运行

### Q: 如何调试？

A: 
1. 打开扩展的"背景页"查看后台脚本日志
2. 在弹出窗口右键选择"检查"查看 DevTools
3. 使用 `chrome.runtime.sendMessage` 测试消息通信

## 更新日志

### v1.1.0
- 与主应用 v1.1.0 版本对齐

### v1.0.0
- 基础扩展功能
- Popup 快速操作
- Side Panel 支持
- 数据加密存储
- 多浏览器支持
