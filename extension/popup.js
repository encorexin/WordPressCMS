/**
 * 扩展弹出窗口脚本
 * 处理快速操作和统计信息展示
 */

// 初始化
document.addEventListener('DOMContentLoaded', async () => {
  try {
    await loadStats();
    setupEventListeners();
  } catch (error) {
    console.error('初始化失败:', error);
    showError('初始化失败，请刷新页面重试');
  }
});

/**
 * 从 Chrome Storage 加载统计数据
 */
async function loadStats() {
  const loading = document.getElementById('loading');
  if (loading) loading.classList.add('active');

  try {
    // 检查 chrome.storage 是否可用
    if (!chrome.storage || !chrome.storage.local) {
      throw new Error('Chrome Storage 不可用');
    }

    // 从 Chrome Storage 获取数据
    const result = await chrome.storage.local.get([
      'wp_cms_stats',
      'wp_cms_articles',
      'wp_cms_sites',
      'wp_cms_templates'
    ]);

    // 更新统计
    const articles = result.wp_cms_articles || [];
    const sites = result.wp_cms_sites || [];
    const templates = result.wp_cms_templates || [];

    updateStatDisplay('article-count', articles.length);
    updateStatDisplay('site-count', sites.length);
    updateStatDisplay('template-count', templates.length);

  } catch (error) {
    console.error('加载统计失败:', error);
    // 显示默认数据
    updateStatDisplay('article-count', 0);
    updateStatDisplay('site-count', 0);
    updateStatDisplay('template-count', 0);
  } finally {
    if (loading) loading.classList.remove('active');
  }
}

/**
 * 更新统计显示
 */
function updateStatDisplay(elementId, value) {
  const element = document.getElementById(elementId);
  if (element) {
    element.textContent = value;
  }
}

/**
 * 显示错误信息
 */
function showError(message) {
  const container = document.querySelector('.container');
  if (container) {
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
      background: rgba(220, 38, 38, 0.9);
      color: white;
      padding: 12px;
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 14px;
    `;
    errorDiv.textContent = message;
    container.insertBefore(errorDiv, container.firstChild);
  }
}

/**
 * 设置事件监听器
 */
function setupEventListeners() {
  // 打开侧边栏按钮
  const openSidepanelBtn = document.getElementById('open-sidepanel');
  if (openSidepanelBtn) {
    openSidepanelBtn.addEventListener('click', async () => {
      try {
        // 检查是否支持 sidePanel API
        if (chrome.sidePanel) {
          // 打开侧边栏
          await chrome.sidePanel.open({ windowId: chrome.windows.WINDOW_ID_CURRENT });
          // 关闭弹出窗口
          window.close();
        } else {
          // 不支持侧边栏，在新标签页打开
          chrome.tabs.create({ url: chrome.runtime.getURL('index.extension.html') });
          window.close();
        }
      } catch (error) {
        console.error('打开侧边栏失败:', error);
        // 降级方案：在新标签页打开
        chrome.tabs.create({ url: chrome.runtime.getURL('index.extension.html') });
        window.close();
      }
    });
  }

  // 在新窗口打开按钮
  const openPopupBtn = document.getElementById('open-popup');
  if (openPopupBtn) {
    openPopupBtn.addEventListener('click', () => {
      try {
        chrome.tabs.create({ url: chrome.runtime.getURL('index.extension.html') });
        window.close();
      } catch (error) {
        console.error('打开新窗口失败:', error);
        showError('打开新窗口失败');
      }
    });
  }
}

/**
 * 更新统计数据（供后台脚本调用）
 */
function updateStats(stats) {
  if (stats.articles !== undefined) {
    updateStatDisplay('article-count', stats.articles);
  }
  if (stats.sites !== undefined) {
    updateStatDisplay('site-count', stats.sites);
  }
  if (stats.templates !== undefined) {
    updateStatDisplay('template-count', stats.templates);
  }
}
