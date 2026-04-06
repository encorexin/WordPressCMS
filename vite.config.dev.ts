
    import { defineConfig, loadConfigFromFile } from "vite";
    import type { Plugin, ConfigEnv, UserConfig } from "vite";
    import tailwindcss from "tailwindcss";
    import autoprefixer from "autoprefixer";
    import fs from "fs/promises";
    import path from "path";
    import {
      makeTagger,
      injectedGuiListenerPlugin,
      injectOnErrorPlugin
    } from "miaoda-sc-plugin";

    const tailwindConfig = {
      plugins: [
        function ({ addUtilities }) {
          addUtilities(
            {
              ".border-t-solid": { "border-top-style": "solid" },
              ".border-r-solid": { "border-right-style": "solid" },
              ".border-b-solid": { "border-bottom-style": "solid" },
              ".border-l-solid": { "border-left-style": "solid" },
              ".border-t-dashed": { "border-top-style": "dashed" },
              ".border-r-dashed": { "border-right-style": "dashed" },
              ".border-b-dashed": { "border-bottom-style": "dashed" },
              ".border-l-dashed": { "border-left-style": "dashed" },
              ".border-t-dotted": { "border-top-style": "dotted" },
              ".border-r-dotted": { "border-right-style": "dotted" },
              ".border-b-dotted": { "border-bottom-style": "dotted" },
              ".border-l-dotted": { "border-left-style": "dotted" },
            },
            ["responsive"]
          );
        },
      ],
    };

    export async function tryLoadConfigFromFile(
      filePath: string,
      env: ConfigEnv = { command: "serve", mode: "development" }
    ): Promise<UserConfig | null> {
      try {
        const result = await loadConfigFromFile(env, filePath);
        return result ? result.config : null;
      } catch (error) {
        console.warn(`加载配置文件失败: ${filePath}，尝试加载 cjs 版本`);
        console.warn(error);

        // 👇 创建 .cjs 临时文件重试
        const tempFilePath =
          filePath.replace(/\.(js|ts|mjs|mts)$/, "") + `.temp.cjs`;
        try {
          const originalContent = await fs.readFile(filePath, "utf-8");

          // 补充逻辑：如果是 ESM 语法，无法直接 require，会失败
          if (/^\s*import\s+/m.test(originalContent)) {
            console.error(
              `配置文件包含 import 语法，无法自动转为 CommonJS: ${filePath}`
            );
            return null;
          }

          await fs.writeFile(tempFilePath, originalContent, "utf-8");

          const result = await loadConfigFromFile(env, tempFilePath);
          return result ? result.config : null;
        } catch (innerError) {
          console.error(`重试加载临时 .cjs 文件失败: ${tempFilePath}`);
          console.error(innerError);
          return null;
        } finally {
          // 🧹 尝试删除临时文件
          try {
            await fs.unlink(tempFilePath);
          } catch (_unlinkError: unknown) {
            // 临时文件清理失败可以安全忽略
          }
        }
      }
    }

    const env: ConfigEnv = { command: "serve", mode: "development" };
    const configFile = path.resolve(__dirname, "vite.config.ts");
    const result = await loadConfigFromFile(env, configFile);
    const userConfig = result?.config;
    const tailwindConfigFile = path.resolve(__dirname, "tailwind.config.js");
    const tailwindResult = await tryLoadConfigFromFile(tailwindConfigFile, env);
    const root = path.resolve(__dirname);

    export default defineConfig({
      ...userConfig,
      plugins: [
        makeTagger(),
        injectedGuiListenerPlugin({
          path: 'https://resource-static.cdn.bcebos.com/common/v2/injected.js'
        }),
        injectOnErrorPlugin(),
        ...(userConfig?.plugins || []),
        
{
  name: 'hmr-toggle',
  configureServer(server) {
    let hmrEnabled = true;

    // 包装原来的 send 方法
    const _send = server.ws.send;
    server.ws.send = (payload) => {
      if (hmrEnabled) {
        return _send.call(server.ws, payload);
      } else {
        console.log('[HMR disabled] skipped payload:', payload.type);
      }
    };

    // 提供接口切换 HMR
    server.middlewares.use('/innerapi/v1/sourcecode/__hmr_off', (req, res) => {
      hmrEnabled = false;
      let body = {
          status: 0,
          msg: 'HMR disabled'
      };
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(body));
    });

    server.middlewares.use('/innerapi/v1/sourcecode/__hmr_on', (req, res) => {
      hmrEnabled = true;
      let body = {
          status: 0,
          msg: 'HMR enabled'
      };
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(body));
    });

    // 注册一个 HTTP API，用来手动触发一次整体刷新
    server.middlewares.use('/innerapi/v1/sourcecode/__hmr_reload', (req, res) => {
      if (hmrEnabled) {
        server.ws.send({
          type: 'full-reload',
          path: '*', // 整页刷新
        });
      }
      res.statusCode = 200;
      let body = {
          status: 0,
          msg: 'Manual full reload triggered'
      };
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify(body));
    });
  },
  load(id) {
    if (id === 'virtual:after-update') {
      return `
        if (import.meta.hot) {
          import.meta.hot.on('vite:afterUpdate', () => {
            window.postMessage(
              {
                type: 'editor-update'
              },
              '*'
            );
          });
        }
      `;
    }
  },
  transformIndexHtml(html) {
    return {
      html,
      tags: [
        {
          tag: 'script',
          attrs: {
            type: 'module',
            src: '/@id/virtual:after-update'
          },
          injectTo: 'body'
        }
      ]
    };
  }
},

      ],
      css: {
        postcss: {
          plugins: [
            tailwindcss({
              ...(tailwindResult as Record<string, unknown>),
              content: [`${root}/index.html`, `${root}/src/**/*.{js,ts,jsx,tsx}`],
            }),
            autoprefixer(),
          ],
        },
      }
    });
    