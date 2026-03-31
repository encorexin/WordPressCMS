/**
 * 扩展后台 Service Worker
 * 处理后台任务、数据同步和消息通信
 */

// 安装时初始化
chrome.runtime.onInstalled.addListener((details) => {
  console.log('WordPress CMS 助手已安装', details);
  
  // 初始化存储
  initializeStorage();
  
  // 设置定时任务（如需要）
  setupAlarms();
});

/**
 * 初始化存储
 */
async function initializeStorage() {
  const defaults = {
    wp_cms_stats: {
      articles: 0,
      sites: 0,
      templates: 0,
      keywords: 0,
      topics: 0
    },
    wp_cms_articles: [],
    wp_cms_sites: [],
    wp_cms_templates: [],
    wp_cms_settings: {
      theme: 'system',
      language: 'zh-CN'
    }
  };
  
  const existing = await chrome.storage.local.get(Object.keys(defaults));
  const updates = {};
  
  for (const [key, value] of Object.entries(defaults)) {
    if (existing[key] === undefined) {
      updates[key] = value;
    }
  }
  
  if (Object.keys(updates).length > 0) {
    await chrome.storage.local.set(updates);
    console.log('初始化存储完成:', updates);
  }
}

/**
 * 设置定时任务
 */
function setupAlarms() {
  // 每小时更新一次统计
  chrome.alarms.create('updateStats', { periodInMinutes: 60 });
}

/**
 * 处理定时任务
 */
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'updateStats') {
    updateStatistics();
  }
});

/**
 * 更新统计数据
 */
async function updateStatistics() {
  try {
    // 从 IndexedDB 读取数据并更新 Chrome Storage
    // 注意：Service Worker 无法直接访问 IndexedDB
    // 需要通过消息传递让内容脚本或弹出窗口处理
    
    // 广播消息给所有连接的端口
    broadcastMessage({
      type: 'UPDATE_STATS_REQUEST'
    });
  } catch (error) {
    console.error('更新统计失败:', error);
  }
}

/**
 * 处理消息通信
 */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('收到消息:', message, '来自:', sender);
  
  switch (message.type) {
    case 'GET_STATS':
      handleGetStats(sendResponse);
      return true; // 保持连接以支持异步响应
      
    case 'UPDATE_STATS':
      handleUpdateStats(message.data, sendResponse);
      return true;
      
    case 'SYNC_DATA':
      handleSyncData(message.data, sendResponse);
      return true;
      
    case 'OPEN_SIDEPANEL':
      handleOpenSidepanel(sendResponse);
      return true;
      
    default:
      sendResponse({ error: '未知消息类型' });
  }
});

/**
 * 处理获取统计请求
 */
async function handleGetStats(sendResponse) {
  try {
    const result = await chrome.storage.local.get([
      'wp_cms_stats',
      'wp_cms_articles',
      'wp_cms_sites',
      'wp_cms_templates'
    ]);
    
    sendResponse({
      success: true,
      data: {
        stats: result.wp_cms_stats,
        articles: result.wp_cms_articles,
        sites: result.wp_cms_sites,
        templates: result.wp_cms_templates
      }
    });
  } catch (error) {
    sendResponse({
      success: false,
      error: error.message
    });
  }
}

/**
 * 处理更新统计请求
 */
async function handleUpdateStats(data, sendResponse) {
  try {
    await chrome.storage.local.set({
      'wp_cms_stats': data.stats,
      'wp_cms_articles': data.articles,
      'wp_cms_sites': data.sites,
      'wp_cms_templates': data.templates
    });
    
    // 广播更新给所有弹出窗口
    broadcastMessage({
      type: 'STATS_UPDATED',
      data: data.stats
    });
    
    sendResponse({ success: true });
  } catch (error) {
    sendResponse({
      success: false,
      error: error.message
    });
  }
}

/**
 * 处理数据同步请求
 */
async function handleSyncData(data, sendResponse) {
  try {
    // 这里可以实现与远程服务器的同步逻辑
    // 或者与其他设备的数据同步
    
    console.log('同步数据:', data);
    sendResponse({ success: true });
  } catch (error) {
    sendResponse({
      success: false,
      error: error.message
    });
  }
}

/**
 * 处理打开侧边栏请求
 */
async function handleOpenSidepanel(sendResponse) {
  try {
    if (chrome.sidePanel) {
      await chrome.sidePanel.open({ windowId: chrome.windows.WINDOW_ID_CURRENT });
      sendResponse({ success: true });
    } else {
      sendResponse({
        success: false,
        error: '不支持侧边栏 API'
      });
    }
  } catch (error) {
    sendResponse({
      success: false,
      error: error.message
    });
  }
}

/**
 * 广播消息给所有连接的端口
 */
function broadcastMessage(message) {
  chrome.runtime.sendMessage(message).catch(() => {
    // 忽略没有接收者的错误
  });
}

/**
 * 处理外部消息（来自网页）
 */
chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  console.log('收到外部消息:', message);
  
  // 可以在这里处理来自 WordPress 网站的消息
  // 例如：获取文章列表、发布文章等
  
  sendResponse({ success: true });
  return true;
});

// 保持 Service Worker 活跃
chrome.runtime.onStartup.addListener(() => {
  console.log('扩展已启动');
});
