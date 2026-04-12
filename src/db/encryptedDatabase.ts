/**
 * 加密数据库服务
 * 所有敏感数据都通过用户密码加密存储
 */

import { generateId, getTimestamp } from "./models";
import { legacyDb } from "./legacyDatabase";
import { storageLogger } from '@/utils/logger';
import type {
    LocalArticle,
    LocalWordPressSite,
    AISettings,
    ArticleTemplate,
    Keyword,
    Topic,
    ArticleVersion
} from "./models";
import {
    saveEncryptedData,
    loadEncryptedData,
    removeEncryptedData,
    hasEncryptedData,
    exportEncryptedData,
    importEncryptedData,
    clearAllUserData,
    isEncryptionEnabled,
    setEncryptionKey,
    hasEncryptionKey
} from '@/utils/encryptedStorage';

// 数据类型定义
const DATA_TYPES = {
    ARTICLES: 'articles',
    SITES: 'sites',
    AI_SETTINGS: 'ai_settings',
    TEMPLATES: 'templates',
    KEYWORDS: 'keywords',
    TOPICS: 'topics',
    ARTICLE_VERSIONS: 'article_versions',
} as const;

// ==================== 文章相关 ====================

export async function getEncryptedArticles(userId: string): Promise<LocalArticle[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const articles = await loadEncryptedData<LocalArticle[]>(userId, DATA_TYPES.ARTICLES);
    return articles || [];
}

export async function saveEncryptedArticle(userId: string, article: LocalArticle): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const articles = await getEncryptedArticles(userId);
    const index = articles.findIndex(a => a.id === article.id);

    if (index >= 0) {
        articles[index] = { ...article, updated_at: getTimestamp() };
    } else {
        articles.push({
            ...article,
            created_at: getTimestamp(),
            updated_at: getTimestamp(),
        });
    }

    await saveEncryptedData(userId, DATA_TYPES.ARTICLES, articles);
}

export async function deleteEncryptedArticle(userId: string, articleId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const articles = await getEncryptedArticles(userId);
    const filtered = articles.filter(a => a.id !== articleId);
    await saveEncryptedData(userId, DATA_TYPES.ARTICLES, filtered);
}

export async function getEncryptedArticleById(userId: string, articleId: string): Promise<LocalArticle | null> {
    const articles = await getEncryptedArticles(userId);
    return articles.find(a => a.id === articleId) || null;
}

// ==================== WordPress 站点相关 ====================

export async function getEncryptedSites(userId: string): Promise<LocalWordPressSite[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const sites = await loadEncryptedData<LocalWordPressSite[]>(userId, DATA_TYPES.SITES);
    return sites || [];
}

export async function saveEncryptedSite(userId: string, site: LocalWordPressSite): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const sites = await getEncryptedSites(userId);
    const index = sites.findIndex(s => s.id === site.id);

    if (index >= 0) {
        sites[index] = { ...site, updated_at: getTimestamp() };
    } else {
        sites.push({
            ...site,
            created_at: getTimestamp(),
            updated_at: getTimestamp(),
        });
    }

    await saveEncryptedData(userId, DATA_TYPES.SITES, sites);
}

export async function deleteEncryptedSite(userId: string, siteId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const sites = await getEncryptedSites(userId);
    const filtered = sites.filter(s => s.id !== siteId);
    await saveEncryptedData(userId, DATA_TYPES.SITES, filtered);
}

// ==================== AI 设置相关 ====================

export async function getEncryptedAISettings(userId: string): Promise<AISettings | null> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const stored = await loadEncryptedData<AISettings | AISettings[]>(userId, DATA_TYPES.AI_SETTINGS);
    if (!stored) return null;
    if (Array.isArray(stored)) {
        const defaultSettings = stored.find(s => s.is_default) || stored[0];
        return defaultSettings || null;
    }
    return stored;
}

export async function saveEncryptedAISettings(userId: string, settings: AISettings): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const list = await getEncryptedAISettingsList(userId);
    if (list.length === 0) {
        const newSettings: AISettings = {
            ...settings,
            id: settings.id || generateId(),
            user_id: userId,
            name: settings.name || "默认配置",
            is_default: true,
            created_at: settings.created_at || getTimestamp(),
            updated_at: getTimestamp(),
        };
        await saveEncryptedData(userId, DATA_TYPES.AI_SETTINGS, [newSettings]);
        return;
    }

    const defaultIndex = list.findIndex(s => s.is_default);
    const targetIndex = defaultIndex >= 0 ? defaultIndex : 0;
    const existing = list[targetIndex];
    const updated: AISettings = {
        ...existing,
        ...settings,
        id: existing.id,
        user_id: userId,
        name: existing.name || settings.name || "默认配置",
        is_default: true,
        created_at: existing.created_at,
        updated_at: getTimestamp(),
    };

    const next = list.map((s, index) => {
        if (index === targetIndex) {
            return updated;
        }
        return { ...s, is_default: false };
    });
    await saveEncryptedData(userId, DATA_TYPES.AI_SETTINGS, next);
}

export async function getEncryptedAISettingsList(userId: string): Promise<AISettings[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const stored = await loadEncryptedData<AISettings | AISettings[]>(userId, DATA_TYPES.AI_SETTINGS);
    if (!stored) return [];
    if (Array.isArray(stored)) {
        return stored.map(s => ({
            ...s,
            name: s.name || "默认配置",
            is_default: s.is_default ?? false,
        }));
    }
    const normalized: AISettings = {
        ...stored,
        id: stored.id || generateId(),
        user_id: userId,
        name: stored.name || "默认配置",
        is_default: true,
        created_at: stored.created_at || getTimestamp(),
        updated_at: stored.updated_at || getTimestamp(),
    };
    await saveEncryptedData(userId, DATA_TYPES.AI_SETTINGS, [normalized]);
    return [normalized];
}

export async function setEncryptedAISettingsList(userId: string, settingsList: AISettings[]): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    await saveEncryptedData(userId, DATA_TYPES.AI_SETTINGS, settingsList);
}

// ==================== 模板相关 ====================

export async function getEncryptedTemplates(userId: string): Promise<ArticleTemplate[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const templates = await loadEncryptedData<ArticleTemplate[]>(userId, DATA_TYPES.TEMPLATES);
    return templates || [];
}

export async function setEncryptedTemplates(userId: string, templates: ArticleTemplate[]): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    await saveEncryptedData(userId, DATA_TYPES.TEMPLATES, templates);
}

export async function saveEncryptedTemplate(userId: string, template: ArticleTemplate): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const templates = await getEncryptedTemplates(userId);
    const index = templates.findIndex(t => t.id === template.id);

    if (index >= 0) {
        templates[index] = { ...template, updated_at: getTimestamp() };
    } else {
        templates.push({
            ...template,
            created_at: getTimestamp(),
            updated_at: getTimestamp(),
        });
    }

    await saveEncryptedData(userId, DATA_TYPES.TEMPLATES, templates);
}

export async function deleteEncryptedTemplate(userId: string, templateId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const templates = await getEncryptedTemplates(userId);
    const filtered = templates.filter(t => t.id !== templateId);
    await saveEncryptedData(userId, DATA_TYPES.TEMPLATES, filtered);
}

// ==================== 关键词相关 ====================

export async function getEncryptedKeywords(userId: string): Promise<Keyword[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const keywords = await loadEncryptedData<Keyword[]>(userId, DATA_TYPES.KEYWORDS);
    return keywords || [];
}

export async function setEncryptedKeywords(userId: string, keywords: Keyword[]): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    await saveEncryptedData(userId, DATA_TYPES.KEYWORDS, keywords);
}

export async function saveEncryptedKeyword(userId: string, keyword: Keyword): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const keywords = await getEncryptedKeywords(userId);
    const index = keywords.findIndex(k => k.id === keyword.id);

    if (index >= 0) {
        keywords[index] = keyword;
    } else {
        keywords.push(keyword);
    }

    await saveEncryptedData(userId, DATA_TYPES.KEYWORDS, keywords);
}

export async function deleteEncryptedKeyword(userId: string, keywordId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const keywords = await getEncryptedKeywords(userId);
    const filtered = keywords.filter(k => k.id !== keywordId);
    await saveEncryptedData(userId, DATA_TYPES.KEYWORDS, filtered);
}

// ==================== 主题相关 ====================

export async function getEncryptedTopics(userId: string): Promise<Topic[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const topics = await loadEncryptedData<Topic[]>(userId, DATA_TYPES.TOPICS);
    return topics || [];
}

export async function setEncryptedTopics(userId: string, topics: Topic[]): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    await saveEncryptedData(userId, DATA_TYPES.TOPICS, topics);
}

export async function saveEncryptedTopic(userId: string, topic: Topic): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const topics = await getEncryptedTopics(userId);
    const index = topics.findIndex(t => t.id === topic.id);

    if (index >= 0) {
        topics[index] = topic;
    } else {
        topics.push(topic);
    }

    await saveEncryptedData(userId, DATA_TYPES.TOPICS, topics);
}

export async function deleteEncryptedTopic(userId: string, topicId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const topics = await getEncryptedTopics(userId);
    const filtered = topics.filter(t => t.id !== topicId);
    await saveEncryptedData(userId, DATA_TYPES.TOPICS, filtered);
}

// ==================== 文章版本相关 ====================

export async function getEncryptedArticleVersions(userId: string, articleId: string): Promise<ArticleVersion[]> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const allVersions = await loadEncryptedData<ArticleVersion[]>(userId, DATA_TYPES.ARTICLE_VERSIONS);
    if (!allVersions) return [];
    return allVersions.filter(v => v.article_id === articleId);
}

export async function saveEncryptedArticleVersion(userId: string, version: ArticleVersion): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const allVersions = await loadEncryptedData<ArticleVersion[]>(userId, DATA_TYPES.ARTICLE_VERSIONS) || [];
    allVersions.push(version);
    await saveEncryptedData(userId, DATA_TYPES.ARTICLE_VERSIONS, allVersions);
}

export async function deleteEncryptedArticleVersion(userId: string, versionId: string): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    const allVersions = await loadEncryptedData<ArticleVersion[]>(userId, DATA_TYPES.ARTICLE_VERSIONS) || [];
    const filtered = allVersions.filter(v => v.id !== versionId);
    await saveEncryptedData(userId, DATA_TYPES.ARTICLE_VERSIONS, filtered);
}

// ==================== 数据导出/导入 ====================

export async function exportUserData(userId: string): Promise<{
    version: number;
    timestamp: string;
    data: Record<string, unknown>;
}> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    return await exportEncryptedData(userId);
}

export async function importUserData(
    userId: string,
    backup: {
        version: number;
        timestamp: string;
        data: Record<string, unknown>;
    }
): Promise<void> {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或密钥未设置');
    }
    await importEncryptedData(userId, backup);
}

// ==================== 数据清理 ====================

export function clearUserData(userId: string): void {
    clearAllUserData(userId);
}

// ==================== 迁移工具 ====================

/**
 * 从旧版 Dexie 数据库迁移数据到加密存储
 */
export async function migrateFromDexie(
    userId: string,
    password: string
): Promise<{ success: boolean; message: string }> {
    try {
        // 设置加密密钥
        setEncryptionKey(userId, password);

        // 迁移文章
        const articles = await legacyDb.articles.where('user_id').equals(userId).toArray();
        if (articles.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.ARTICLES, articles, password);
        }

        // 迁移站点
        const sites = await legacyDb.wordpress_sites.where('user_id').equals(userId).toArray();
        if (sites.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.SITES, sites, password);
        }

        // 迁移 AI 设置
        const aiSettings = await legacyDb.ai_settings.where('user_id').equals(userId).first();
        if (aiSettings) {
            await saveEncryptedData(userId, DATA_TYPES.AI_SETTINGS, aiSettings, password);
        }

        // 迁移模板
        const templates = await legacyDb.article_templates.where('user_id').equals(userId).toArray();
        if (templates.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.TEMPLATES, templates, password);
        }

        // 迁移关键词
        const keywords = await legacyDb.keywords.where('user_id').equals(userId).toArray();
        if (keywords.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.KEYWORDS, keywords, password);
        }

        // 迁移主题
        const topics = await legacyDb.topics.where('user_id').equals(userId).toArray();
        if (topics.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.TOPICS, topics, password);
        }

        // 迁移文章版本
        const versions = await legacyDb.article_versions.where('user_id').equals(userId).toArray();
        if (versions.length > 0) {
            await saveEncryptedData(userId, DATA_TYPES.ARTICLE_VERSIONS, versions, password);
        }

        return { success: true, message: '数据迁移成功' };
    } catch (error) {
        storageLogger.error('数据迁移失败:', error);
        return { success: false, message: '数据迁移失败: ' + (error as Error).message };
    }
}

export { isEncryptionEnabled, hasEncryptionKey };
