/**
 * Vite 配置 - 浏览器扩展构建
 * 用于构建 Chrome/Firefox/Edge 扩展
 */

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import path from 'path';
import { copyFileSync, mkdirSync, existsSync } from 'fs';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    svgr({
      svgrOptions: {
        icon: true,
        exportType: 'named',
        namedExport: 'ReactComponent',
      },
    }),
    {
      name: 'copy-extension-files',
      closeBundle() {
        // 复制扩展文件到 dist 目录
        const extensionDir = path.resolve(__dirname, 'extension');
        const distDir = path.resolve(__dirname, 'dist');
        
        // 复制 manifest.json
        copyFileSync(
          path.join(extensionDir, 'manifest.json'),
          path.join(distDir, 'manifest.json')
        );
        
        // 复制 popup.html
        copyFileSync(
          path.join(extensionDir, 'popup.html'),
          path.join(distDir, 'popup.html')
        );
        
        // 复制 popup.js
        copyFileSync(
          path.join(extensionDir, 'popup.js'),
          path.join(distDir, 'popup.js')
        );
        
        // 复制 background.js
        copyFileSync(
          path.join(extensionDir, 'background.js'),
          path.join(distDir, 'background.js')
        );
        
        console.log('扩展文件复制完成');
      }
    }
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // 扩展环境配置
  define: {
    'process.env.IS_EXTENSION': JSON.stringify(true),
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    // 扩展不需要代码分割，打包为单个文件
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, 'index.extension.html'),
      },
      output: {
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: (assetInfo) => {
          const info = assetInfo.name.split('.');
          const ext = info[info.length - 1];
          if (/\.css$/i.test(assetInfo.name)) {
            return 'assets/[name]-[hash][extname]';
          }
          return 'assets/[name]-[hash][extname]';
        },
      },
    },
  },
});
