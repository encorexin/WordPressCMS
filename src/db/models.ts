export interface LocalUser {
    id: string;
    email: string;
    password_hash: string;
    role: 'user' | 'admin';
    created_at: string;
}

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

export interface AISettings {
    id: string;
    user_id: string;
    name: string;
    is_default: boolean;
    api_endpoint: string;
    api_key: string;
    model: string;
    system_prompt: string;
    image_provider?: 'openai' | 'aliyun' | 'zhipu' | 'stability' | 'baidu' | 'siliconflow' | 'replicate' | 'custom' | '';
    image_api_key?: string;
    image_endpoint?: string;
    image_model?: string;
    image_enabled?: boolean;
    slug_model?: string;
    slug_enabled?: boolean;
    created_at: string;
    updated_at: string;
}

export interface ArticleTemplate {
    id: string;
    user_id: string;
    name: string;
    description: string;
    system_prompt: string;
    created_at: string;
    updated_at: string;
}

export interface Keyword {
    id: string;
    user_id: string;
    keyword: string;
    group_name: string;
    use_count: number;
    created_at: string;
}

export interface Topic {
    id: string;
    user_id: string;
    title: string;
    description: string;
    keywords: string;
    category: string;
    used: boolean;
    created_at: string;
}

export interface ArticleVersion {
    id: string;
    article_id: string;
    user_id: string;
    title: string;
    content: string | null;
    keywords: string | null;
    template: string | null;
    version_number: number;
    created_at: string;
}

export function generateId(): string {
    return crypto.randomUUID();
}

export function getTimestamp(): string {
    return new Date().toISOString();
}
