/**
 * 浏览器扩展打包脚本
 * 支持 Chrome、Firefox、Edge
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const rootDir = path.resolve(__dirname, '..');
const distDir = path.join(rootDir, 'dist');
const extensionDir = path.join(rootDir, 'extension-build');

/**
 * 主函数
 */
async function main() {
  console.log('🚀 开始构建浏览器扩展...\n');
  
  try {
    // 1. 清理并创建输出目录
    console.log('📁 准备输出目录...');
    if (fs.existsSync(distDir)) {
      fs.rmSync(distDir, { recursive: true });
    }
    if (fs.existsSync(extensionDir)) {
      fs.rmSync(extensionDir, { recursive: true });
    }
    fs.mkdirSync(extensionDir, { recursive: true });
    
    // 2. 使用 Vite 构建
    console.log('🔨 构建 React 应用...');
    execSync('npx vite build --config vite.config.extension.ts', {
      cwd: rootDir,
      stdio: 'inherit'
    });
    
    // 3. 复制扩展文件
    console.log('📋 复制扩展文件...');
    copyExtensionFiles();
    
    // 4. 为不同浏览器创建版本
    console.log('🌐 创建浏览器特定版本...');
    await createBrowserVersions();
    
    // 5. 创建 ZIP 包
    console.log('📦 创建 ZIP 包...');
    createZipPackages();
    
    console.log('\n✅ 扩展构建完成！');
    console.log(`\n输出目录: ${extensionDir}`);
    console.log('\n可用版本:');
    console.log('  - chrome/    Chrome 扩展');
    console.log('  - firefox/   Firefox 扩展');
    console.log('  - edge/      Edge 扩展');
    console.log('\n安装方法:');
    console.log('  Chrome: 打开 chrome://extensions/ → 开启开发者模式 → 加载已解压的扩展程序');
    console.log('  Firefox: 打开 about:debugging → 此 Firefox → 加载临时附加组件');
    console.log('  Edge: 打开 edge://extensions/ → 开启开发者模式 → 加载已解压的扩展程序');
    
  } catch (error) {
    console.error('\n❌ 构建失败:', error.message);
    process.exit(1);
  }
}

/**
 * 复制扩展文件到 dist 目录
 */
function copyExtensionFiles() {
  const extDir = path.join(rootDir, 'extension');
  
  // 复制 manifest.json
  fs.copyFileSync(
    path.join(extDir, 'manifest.json'),
    path.join(distDir, 'manifest.json')
  );
  
  // 复制 popup.html
  fs.copyFileSync(
    path.join(extDir, 'popup.html'),
    path.join(distDir, 'popup.html')
  );
  
  // 复制 popup.js
  fs.copyFileSync(
    path.join(extDir, 'popup.js'),
    path.join(distDir, 'popup.js')
  );
  
  // 复制 background.js
  fs.copyFileSync(
    path.join(extDir, 'background.js'),
    path.join(distDir, 'background.js')
  );
  
  // 创建 icons 目录并复制图标
  const iconsDir = path.join(distDir, 'icons');
  const sourceIconsDir = path.join(extDir, 'icons');
  
  if (fs.existsSync(sourceIconsDir)) {
    // 如果 extension/icons 目录存在，复制其中的图标
    fs.mkdirSync(iconsDir, { recursive: true });
    copyDirectory(sourceIconsDir, iconsDir);
    console.log('  ✅ 已复制扩展图标');
  } else {
    // 如果没有图标，创建默认图标
    fs.mkdirSync(iconsDir, { recursive: true });
    createDefaultIcons(iconsDir);
  }
}

/**
 * 创建默认图标
 */
function createDefaultIcons(iconsDir) {
  const sizes = [16, 32, 48, 128];
  const svgIcon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
    <rect width="128" height="128" rx="20" fill="#667eea"/>
    <text x="64" y="84" font-size="64" text-anchor="middle" fill="white">📝</text>
  </svg>`;
  
  // 保存 SVG
  fs.writeFileSync(path.join(iconsDir, 'icon.svg'), svgIcon);
  
  // 注意：实际项目中应该使用 PNG 图标
  // 这里创建占位文件
  sizes.forEach(size => {
    const placeholder = Buffer.alloc(size * size * 4);
    fs.writeFileSync(path.join(iconsDir, `icon${size}.png`), placeholder);
  });
  
  console.log('  ⚠️  已创建占位图标，请替换为实际图标文件');
}

/**
 * 为不同浏览器创建版本
 */
async function createBrowserVersions() {
  const browsers = ['chrome', 'firefox', 'edge'];
  
  for (const browser of browsers) {
    const browserDir = path.join(extensionDir, browser);
    fs.mkdirSync(browserDir, { recursive: true });
    
    // 复制所有文件
    copyDirectory(distDir, browserDir);
    
    // 修改特定浏览器的 manifest
    await modifyManifestForBrowser(browser, browserDir);
    
    console.log(`  ✅ ${browser} 版本已创建`);
  }
}

/**
 * 为特定浏览器修改 manifest
 */
async function modifyManifestForBrowser(browser, browserDir) {
  const manifestPath = path.join(browserDir, 'manifest.json');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  
  switch (browser) {
    case 'firefox':
      // Firefox 特定修改
      manifest.browser_specific_settings = {
        gecko: {
          id: 'wp-cms-helper@example.com',
          strict_min_version: '109.0'
        }
      };
      // Firefox 使用 browser_action 而不是 action
      manifest.browser_action = manifest.action;
      delete manifest.action;
      // Firefox 不支持 side_panel
      delete manifest.side_panel;
      break;
      
    case 'edge':
      // Edge 特定修改
      manifest.name = 'WordPress CMS 助手 for Edge';
      break;
      
    case 'chrome':
    default:
      // Chrome 使用标准配置
      break;
  }
  
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
}

/**
 * 创建 ZIP 包
 */
function createZipPackages() {
  const browsers = ['chrome', 'firefox', 'edge'];
  
  for (const browser of browsers) {
    const browserDir = path.join(extensionDir, browser);
    const zipPath = path.join(extensionDir, `wp-cms-helper-${browser}.zip`);
    
    try {
      // 使用 PowerShell 创建 ZIP
      const command = `Compress-Archive -Path "${browserDir}\\*" -DestinationPath "${zipPath}" -Force`;
      execSync(command, { stdio: 'ignore' });
      console.log(`  📦 ${browser}.zip 已创建`);
    } catch (error) {
      console.log(`  ⚠️  无法创建 ${browser}.zip，请手动打包`);
    }
  }
}

/**
 * 复制目录
 */
function copyDirectory(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// 运行主函数
main();
