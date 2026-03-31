/**
 * 扩展环境入口文件
 * 适配浏览器扩展的 React 应用
 */

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { HelmetProvider } from 'react-helmet-async';
import App from './App';
import { ExtensionErrorBoundary } from './ExtensionErrorBoundary';
import './index.css';

/**
 * 扩展环境初始化
 */
function initExtension() {
  // 检查是否在扩展环境中运行
  const isExtension = typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.id;

  if (!isExtension) {
    console.warn('不在扩展环境中运行，使用标准模式');
  } else {
    console.log('WordPress CMS 助手 - 扩展模式已启动');
    // 设置扩展环境标志
    window.__IS_EXTENSION__ = true;
  }

  // 创建根元素
  const rootElement = document.getElementById('root');
  if (!rootElement) {
    throw new Error('找不到 root 元素');
  }

  const root = createRoot(rootElement);

  // App 组件内部会根据 __IS_EXTENSION__ 选择 HashRouter 或 BrowserRouter
  root.render(
    <StrictMode>
      <ExtensionErrorBoundary>
        <HelmetProvider>
          <App />
        </HelmetProvider>
      </ExtensionErrorBoundary>
    </StrictMode>
  );
}

// 启动应用
initExtension();

// 类型声明
declare global {
  interface Window {
    __IS_EXTENSION__: boolean;
  }
}
