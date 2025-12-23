/*
# 创建WordPress内容管理系统初始数据库结构

## 1. 新建表

### profiles 表
用户配置表,存储用户基本信息和角色
- `id` (uuid, 主键, 默认: gen_random_uuid())
- `phone` (text, 唯一)
- `email` (text, 唯一)
- `role` (user_role, 默认: 'user', 非空)
- `created_at` (timestamptz, 默认: now())

### wordpress_sites 表
WordPress站点配置表,存储用户添加的WordPress网站信息
- `id` (uuid, 主键, 默认: gen_random_uuid())
- `user_id` (uuid, 外键关联profiles.id)
- `site_name` (text, 非空) - 站点名称
- `site_url` (text, 非空) - WordPress网站地址
- `username` (text, 非空) - WordPress用户名
- `app_password` (text, 非空) - WordPress应用程序密码
- `status` (text, 默认: 'active') - 连接状态: active/inactive
- `created_at` (timestamptz, 默认: now())
- `updated_at` (timestamptz, 默认: now())

### articles 表
文章管理表,存储生成和发布的文章
- `id` (uuid, 主键, 默认: gen_random_uuid())
- `user_id` (uuid, 外键关联profiles.id)
- `site_id` (uuid, 外键关联wordpress_sites.id, 可为空)
- `title` (text, 非空) - 文章标题
- `content` (text) - 文章内容
- `keywords` (text) - 生成文章的关键词
- `template` (text) - 使用的模板
- `status` (text, 默认: 'draft') - 状态: draft/published
- `wordpress_post_id` (text) - WordPress文章ID
- `created_at` (timestamptz, 默认: now())
- `updated_at` (timestamptz, 默认: now())

## 2. 安全策略

### profiles 表
- 启用RLS
- 管理员拥有所有权限
- 用户可以查看和更新自己的资料

### wordpress_sites 表
- 启用RLS
- 管理员可以查看所有站点
- 用户只能管理自己的站点（增删改查）

### articles 表
- 启用RLS
- 管理员可以查看所有文章
- 用户只能管理自己的文章（增删改查）

## 3. 触发器

创建触发器自动将第一个注册用户设置为管理员

## 4. ENUM类型

- user_role: 'user', 'admin'
*/

-- 创建用户角色枚举类型
CREATE TYPE user_role AS ENUM ('user', 'admin');

-- 创建profiles表
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone text UNIQUE,
  email text UNIQUE,
  role user_role DEFAULT 'user'::user_role NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 创建wordpress_sites表
CREATE TABLE IF NOT EXISTS wordpress_sites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  site_name text NOT NULL,
  site_url text NOT NULL,
  username text NOT NULL,
  app_password text NOT NULL,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 创建articles表
CREATE TABLE IF NOT EXISTS articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  site_id uuid REFERENCES wordpress_sites(id) ON DELETE SET NULL,
  title text NOT NULL,
  content text,
  keywords text,
  template text,
  status text DEFAULT 'draft',
  wordpress_post_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 启用RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wordpress_sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;

-- 创建管理员检查函数
CREATE OR REPLACE FUNCTION is_admin(uid uuid)
RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = uid AND p.role = 'admin'::user_role
  );
$$;

-- profiles表策略
CREATE POLICY "管理员拥有所有权限" ON profiles
  FOR ALL TO authenticated USING (is_admin(auth.uid()));

CREATE POLICY "用户可以查看自己的资料" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "用户可以更新自己的资料" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- wordpress_sites表策略
CREATE POLICY "管理员可以查看所有站点" ON wordpress_sites
  FOR SELECT TO authenticated USING (is_admin(auth.uid()));

CREATE POLICY "用户可以查看自己的站点" ON wordpress_sites
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户可以创建自己的站点" ON wordpress_sites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户可以更新自己的站点" ON wordpress_sites
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户可以删除自己的站点" ON wordpress_sites
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "管理员可以管理所有站点" ON wordpress_sites
  FOR ALL TO authenticated USING (is_admin(auth.uid()));

-- articles表策略
CREATE POLICY "管理员可以查看所有文章" ON articles
  FOR SELECT TO authenticated USING (is_admin(auth.uid()));

CREATE POLICY "用户可以查看自己的文章" ON articles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "用户可以创建自己的文章" ON articles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "用户可以更新自己的文章" ON articles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "用户可以删除自己的文章" ON articles
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "管理员可以管理所有文章" ON articles
  FOR ALL TO authenticated USING (is_admin(auth.uid()));

-- 创建触发器函数：首位用户自动成为管理员
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  user_count int;
BEGIN
  -- 只在 confirmed_at 从 NULL → 非 NULL 时执行
  IF OLD.confirmed_at IS NULL AND NEW.confirmed_at IS NOT NULL THEN
    -- 判断 profiles 表里有多少用户
    SELECT COUNT(*) INTO user_count FROM profiles;
    -- 插入 profiles，首位用户给 admin 角色
    INSERT INTO profiles (id, phone, email, role)
    VALUES (
      NEW.id,
      NEW.phone,
      NEW.email,
      CASE WHEN user_count = 0 THEN 'admin'::user_role ELSE 'user'::user_role END
    );
  END IF;
  RETURN NEW;
END;
$$;

-- 绑定触发器到 auth.users 表
DROP TRIGGER IF EXISTS on_auth_user_confirmed ON auth.users;
CREATE TRIGGER on_auth_user_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- 插入初始数据：示例WordPress站点模板
INSERT INTO wordpress_sites (id, user_id, site_name, site_url, username, app_password, status)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles WHERE role = 'admin'::user_role LIMIT 1),
  '示例站点',
  'https://example.com',
  'admin',
  'xxxx xxxx xxxx xxxx xxxx xxxx',
  'inactive'
WHERE EXISTS (SELECT 1 FROM profiles WHERE role = 'admin'::user_role LIMIT 1);

-- 插入初始数据：示例文章
INSERT INTO articles (id, user_id, site_id, title, content, keywords, template, status)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles WHERE role = 'admin'::user_role LIMIT 1),
  NULL,
  '欢迎使用WordPress内容管理系统',
  '这是一个示例文章，您可以使用本系统生成高质量的文章内容并发布到您的WordPress网站。',
  'WordPress, 内容管理, AI生成',
  '默认模板',
  'draft'
WHERE EXISTS (SELECT 1 FROM profiles WHERE role = 'admin'::user_role LIMIT 1);
