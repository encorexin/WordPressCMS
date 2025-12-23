// 数据库类型定义 - 本地数据库版本

export type UserRole = 'user' | 'admin';

// Profile 类型 - 与 LocalUser 兼容
export interface Profile {
  id: string;
  email: string;
  password_hash?: string;  // 可选，不在前端使用
  role: UserRole;
  created_at: string;
}

export interface WordPressSite {
  id: string;
  user_id: string;
  site_name: string;
  site_url: string;
  username: string;
  app_password: string;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface Article {
  id: string;
  user_id: string;
  site_id: string | null;
  title: string;
  content: string | null;
  keywords: string | null;
  template: string | null;
  status: string;
  wordpress_post_id: string | null;
  created_at: string;
  updated_at: string;
}

// 扩展类型（包含关联数据）
export interface ArticleWithSite extends Article {
  site?: WordPressSite;
}

// 表单输入类型
export interface WordPressSiteInput {
  site_name: string;
  site_url: string;
  username: string;
  app_password: string;
}

export interface ArticleInput {
  title: string;
  content?: string;
  keywords?: string;
  template?: string;
  site_id?: string;
}

// AI生成文章请求
export interface GenerateArticleRequest {
  keywords: string;
  template?: string;
}
