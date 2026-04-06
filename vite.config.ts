import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import path from 'path';

// https://vite.dev/config/
export default defineConfig({
  base: './',
  plugins: [
    react(),
    svgr({
      svgrOptions: {
        icon: true,
        exportType: 'named',
        namedExport: 'ReactComponent',
      },
    }),
    // 去除 crossorigin 属性 + 注入错误捕获脚本，兼容 HarmonyOS WebView 本地加载
    {
      name: 'harmonyos-compat',
      enforce: 'post',
      transformIndexHtml(html) {
        // 1. 去除 crossorigin 属性
        let result = html.replace(/ crossorigin/g, '');
        // 2. 在 <head> 最前面注入全局错误捕获（必须在 type="module" 之前同步加载）
        const errorCaptureScript = `<script>
window.onerror=function(m,u,l,c,e){document.title='ERR:'+m;console.error('[GLOBAL]',m,u,l,c,e)};
window.addEventListener('unhandledrejection',function(e){document.title='REJ:'+e.reason;console.error('[REJECTION]',e.reason)});
</script>`;
        result = result.replace('<head>', '<head>\n' + errorCaptureScript);
        return result;
      },
    },
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // SPA 路由回退配置
  preview: {
    port: 4173,
  },
  build: {
    target: 'es2020',
    cssCodeSplit: true,
    sourcemap: false,
    chunkSizeWarningLimit: 1000,
    modulePreload: false,
    rollupOptions: {
      output: {
        manualChunks(id) {
          // React 核心
          if (
            id.includes('node_modules/react/') ||
            id.includes('node_modules/react-dom/') ||
            id.includes('node_modules/react-router-dom/') ||
            id.includes('node_modules/react-router/')
          ) {
            return 'vendor-react';
          }
          // Radix UI 组件库
          if (id.includes('node_modules/@radix-ui/')) {
            return 'vendor-radix';
          }
          // TipTap 编辑器（重依赖，仅编辑器页面使用）
          if (id.includes('node_modules/@tiptap/')) {
            return 'vendor-editor';
          }
          // Recharts 图表库（重依赖，仅仪表盘使用）
          if (id.includes('node_modules/recharts/') || id.includes('node_modules/d3-')) {
            return 'vendor-charts';
          }
          // 工具库
          if (
            id.includes('node_modules/date-fns/') ||
            id.includes('node_modules/zod/') ||
            id.includes('node_modules/clsx/') ||
            id.includes('node_modules/class-variance-authority/') ||
            id.includes('node_modules/tailwind-merge/') ||
            id.includes('node_modules/lucide-react/')
          ) {
            return 'vendor-utils';
          }
        },
      },
    },
  },
});
