# 部署指南

本文档介绍如何将 WordPress CMS Web 应用部署到生产环境。

---

## 构建项目

```bash
pnpm install
pnpm build
```

构建完成后，所有静态文件输出到 `dist/` 目录。

---

## 部署方式

### 方式一：静态文件服务器（推荐）

本项目是纯前端应用，只需将 `dist/` 目录部署到任意静态文件服务器。

#### Nginx 配置示例

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/wordpress-cms/dist;
    index index.html;

    # 处理 SPA 路由
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 缓存静态资源
    location /assets {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;
}
```

#### Apache 配置示例

在 `dist/` 目录下创建 `.htaccess` 文件：

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule ^index\.html$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.html [L]
</IfModule>

<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
</IfModule>
```

---

### 方式二：Vercel

1. 将代码推送到 GitHub
2. 访问 [vercel.com](https://vercel.com)
3. 导入 GitHub 仓库
4. 框架预设选择 **Vite**
5. 点击 **Deploy**

---

### 方式三：Netlify

1. 将代码推送到 GitHub
2. 访问 [netlify.com](https://netlify.com)
3. 点击 **Add new site** → **Import an existing project**
4. 选择 GitHub 仓库
5. 配置：
   - Build command: `pnpm build`
   - Publish directory: `dist`
6. 点击 **Deploy**

---

### 方式四：Docker

创建 `Dockerfile`：

```dockerfile
# 构建阶段
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# 生产阶段
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

创建 `nginx.conf`：

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /assets {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

构建和运行：

```bash
docker build -t wordpress-cms .
docker run -d -p 80:80 wordpress-cms
```

---

## 安全注意事项

- **数据存储**：所有数据存储在用户浏览器本地 IndexedDB，服务器无需存储用户数据
- **API Key**：用户的 AI API Key 仅存储在本地浏览器中
- **WordPress 密码**：应用密码存储在本地，仅用于发布文章时的 API 调用
- **HTTPS**：生产环境建议启用 HTTPS，可使用 [Let's Encrypt](https://letsencrypt.org/) 免费证书

---

## 常见问题

### Q: 刷新页面显示 404？
A: 需要配置服务器将所有路由重定向到 `index.html`，参见上方 Nginx/Apache 配置。

### Q: 部署后数据会丢失吗？
A: 不会。数据存储在用户浏览器的 IndexedDB 中，与部署无关。但清除浏览器数据会丢失。

### Q: 需要配置后端服务吗？
A: 不需要。这是纯前端应用，所有功能都在浏览器中运行。

### Q: 可以部署到子目录吗？
A: 可以。修改 `vite.config.ts` 的 `base` 配置：
```typescript
export default defineConfig({
  base: '/sub-directory/',
})
```
