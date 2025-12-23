import Dexie, { type EntityTable } from 'dexie';

// 用户类型
export interface LocalUser {
    id: string;
    email: string;
    password_hash: string;
    role: 'user' | 'admin';
    created_at: string;
}

// WordPress 站点类型
export interface LocalWordPressSite {
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

// 文章类型
export interface LocalArticle {
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

// AI 设置类型
export interface AISettings {
    id: string;
    user_id: string;
    api_endpoint: string;
    api_key: string;
    model: string;
    system_prompt: string;
    // 图片生成设置
    image_provider?: 'openai' | 'aliyun' | 'zhipu' | 'stability' | 'baidu' | '';
    image_api_key?: string;
    image_model?: string;
    image_enabled?: boolean;
    created_at: string;
    updated_at: string;
}

// 文章模板类型
export interface ArticleTemplate {
    id: string;
    user_id: string;
    name: string;
    description: string;
    system_prompt: string;
    created_at: string;
    updated_at: string;
}

// 关键词类型
export interface Keyword {
    id: string;
    user_id: string;
    keyword: string;
    group_name: string;
    use_count: number;
    created_at: string;
}

// 文章主题类型
export interface Topic {
    id: string;
    user_id: string;
    title: string;           // 主题标题
    description: string;     // 主题描述/大纲
    keywords: string;        // 相关关键词
    category: string;        // 分类
    used: boolean;           // 是否已使用
    created_at: string;
}

// 创建 Dexie 数据库
const db = new Dexie('WordPressCMS') as Dexie & {
    users: EntityTable<LocalUser, 'id'>;
    wordpress_sites: EntityTable<LocalWordPressSite, 'id'>;
    articles: EntityTable<LocalArticle, 'id'>;
    ai_settings: EntityTable<AISettings, 'id'>;
    article_templates: EntityTable<ArticleTemplate, 'id'>;
    keywords: EntityTable<Keyword, 'id'>;
    topics: EntityTable<Topic, 'id'>;
};

// 定义数据库版本和表结构
db.version(5).stores({
    users: 'id, email, role, created_at',
    wordpress_sites: 'id, user_id, site_name, status, created_at',
    articles: 'id, user_id, site_id, title, status, created_at',
    ai_settings: 'id, user_id',
    article_templates: 'id, user_id, name, created_at',
    keywords: 'id, user_id, keyword, group_name, use_count',
    topics: 'id, user_id, title, category, used, created_at'
});

export { db };

// 生成 UUID
export function generateId(): string {
    return crypto.randomUUID();
}

// 获取当前时间 ISO 字符串
export function getTimestamp(): string {
    return new Date().toISOString();
}

