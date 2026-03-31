/**
 * 加密数据 API 层
 * 所有数据操作都通过加密存储进行
 */

import { generateId, getTimestamp } from "./database";
import type {
    LocalUser,
    LocalWordPressSite,
    LocalArticle,
    AISettings,
    ArticleTemplate,
    Keyword,
    Topic,
    ArticleVersion
} from "./database";
import {
    getEncryptedArticles,
    saveEncryptedArticle,
    deleteEncryptedArticle,
    getEncryptedArticleById,
    getEncryptedSites,
    saveEncryptedSite,
    deleteEncryptedSite,
    getEncryptedAISettings,
    saveEncryptedAISettings,
    getEncryptedTemplates,
    saveEncryptedTemplate,
    deleteEncryptedTemplate,
    getEncryptedKeywords,
    saveEncryptedKeyword,
    deleteEncryptedKeyword,
    getEncryptedTopics,
    saveEncryptedTopic,
    deleteEncryptedTopic,
    getEncryptedArticleVersions,
    saveEncryptedArticleVersion,
    deleteEncryptedArticleVersion,
    exportUserData,
    importUserData,
    clearUserData,
    hasEncryptionKey
} from "./encryptedDatabase";

// 重新导出类型以保持兼容性
export type Profile = LocalUser;
export type WordPressSite = LocalWordPressSite;
export type Article = LocalArticle;
export type UserRole = 'user' | 'admin';

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

export interface ArticleWithSite extends Article {
    site?: WordPressSite;
}

// 检查加密密钥是否设置
function checkEncryptionKey(): void {
    if (!hasEncryptionKey()) {
        throw new Error('未登录或数据未解密，请重新登录');
    }
}

// ============ Profiles API ============

export async function getProfile(userId: string): Promise<Profile | null> {
    // 用户信息不加密存储，保持与认证系统兼容
    const { db } = await import('./database');
    const user = await db.users.get(userId);
    return user ?? null;
}

export async function getAllProfiles(): Promise<Profile[]> {
    const { db } = await import('./database');
    return await db.users.orderBy('created_at').reverse().toArray();
}

export async function updateProfile(
    userId: string,
    updates: Partial<Profile>
): Promise<Profile> {
    const { db } = await import('./database');
    await db.users.update(userId, updates);
    const updated = await db.users.get(userId);
    if (!updated) throw new Error("更新失败");
    return updated;
}

// ============ WordPress Sites API ============

export async function getWordPressSites(
    userId?: string
): Promise<WordPressSite[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedSites(userId);
}

export async function getWordPressSite(
    siteId: string,
    userId?: string
): Promise<WordPressSite | null> {
    checkEncryptionKey();
    if (!userId) return null;
    const sites = await getEncryptedSites(userId);
    return sites.find(s => s.id === siteId) || null;
}

export async function createWordPressSite(
    userId: string,
    siteData: WordPressSiteInput
): Promise<WordPressSite> {
    checkEncryptionKey();
    const newSite: WordPressSite = {
        id: generateId(),
        user_id: userId,
        ...siteData,
        status: "active",
        created_at: getTimestamp(),
        updated_at: getTimestamp(),
    };

    await saveEncryptedSite(userId, newSite);
    return newSite;
}

export async function updateWordPressSite(
    userId: string,
    siteId: string,
    updates: Partial<WordPressSiteInput>
): Promise<WordPressSite> {
    checkEncryptionKey();
    const sites = await getEncryptedSites(userId);
    const site = sites.find(s => s.id === siteId);
    if (!site) throw new Error("站点不存在");

    const updatedSite: WordPressSite = {
        ...site,
        ...updates,
        updated_at: getTimestamp(),
    };

    await saveEncryptedSite(userId, updatedSite);
    return updatedSite;
}

export async function deleteWordPressSite(userId: string, siteId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedSite(userId, siteId);
}

export async function updateSiteStatus(
    userId: string,
    siteId: string,
    status: string
): Promise<void> {
    checkEncryptionKey();
    const sites = await getEncryptedSites(userId);
    const site = sites.find(s => s.id === siteId);
    if (!site) throw new Error("站点不存在");

    const updatedSite: WordPressSite = {
        ...site,
        status,
        updated_at: getTimestamp(),
    };

    await saveEncryptedSite(userId, updatedSite);
}

// ============ Articles API ============

export async function getArticles(userId?: string): Promise<ArticleWithSite[]> {
    checkEncryptionKey();
    if (!userId) return [];

    const articles = await getEncryptedArticles(userId);
    const sites = await getEncryptedSites(userId);

    // 获取关联的站点信息
    const articlesWithSite: ArticleWithSite[] = articles.map(article => {
        let site: WordPressSite | undefined;
        if (article.site_id) {
            site = sites.find(s => s.id === article.site_id);
        }
        return { ...article, site };
    });

    return articlesWithSite;
}

export async function getArticle(
    userId: string,
    articleId: string
): Promise<Article | null> {
    checkEncryptionKey();
    return await getEncryptedArticleById(userId, articleId);
}

export async function createArticle(
    userId: string,
    articleData: ArticleInput
): Promise<Article> {
    checkEncryptionKey();
    const newArticle: Article = {
        id: generateId(),
        user_id: userId,
        title: articleData.title,
        content: articleData.content || null,
        keywords: articleData.keywords || null,
        template: articleData.template || "默认模板",
        site_id: articleData.site_id || null,
        status: "draft",
        wordpress_post_id: null,
        created_at: getTimestamp(),
        updated_at: getTimestamp(),
    };

    await saveEncryptedArticle(userId, newArticle);
    return newArticle;
}

export async function updateArticle(
    userId: string,
    articleId: string,
    updates: Partial<ArticleInput>
): Promise<Article> {
    checkEncryptionKey();
    const article = await getEncryptedArticleById(userId, articleId);
    if (!article) throw new Error("文章不存在");

    const updatedArticle: Article = {
        ...article,
        ...updates,
        updated_at: getTimestamp(),
    };

    await saveEncryptedArticle(userId, updatedArticle);
    return updatedArticle;
}

export async function deleteArticle(userId: string, articleId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedArticle(userId, articleId);
}

export async function updateArticleStatus(
    userId: string,
    articleId: string,
    status: string,
    wordpressPostId?: string
): Promise<void> {
    checkEncryptionKey();
    const article = await getEncryptedArticleById(userId, articleId);
    if (!article) throw new Error("文章不存在");

    const updatedArticle: Article = {
        ...article,
        status,
        updated_at: getTimestamp(),
    };

    if (wordpressPostId) {
        updatedArticle.wordpress_post_id = wordpressPostId;
    }

    await saveEncryptedArticle(userId, updatedArticle);
}

// ============ AI Settings API ============

export async function getAISettings(userId: string): Promise<AISettings | null> {
    checkEncryptionKey();
    return await getEncryptedAISettings(userId);
}

export async function saveAISettings(
    userId: string,
    settings: Partial<AISettings>
): Promise<void> {
    checkEncryptionKey();
    const existing = await getEncryptedAISettings(userId);

    const newSettings: AISettings = {
        id: existing?.id || generateId(),
        user_id: userId,
        api_endpoint: settings.api_endpoint || existing?.api_endpoint || '',
        api_key: settings.api_key || existing?.api_key || '',
        model: settings.model || existing?.model || '',
        system_prompt: settings.system_prompt || existing?.system_prompt || '',
        image_enabled: settings.image_enabled ?? existing?.image_enabled ?? false,
        image_provider: settings.image_provider || existing?.image_provider || '',
        image_api_key: settings.image_api_key || existing?.image_api_key || '',
        image_endpoint: settings.image_endpoint || existing?.image_endpoint || '',
        image_model: settings.image_model || existing?.image_model || '',
        slug_enabled: settings.slug_enabled ?? existing?.slug_enabled ?? true,
        slug_model: settings.slug_model || existing?.slug_model || '',
        created_at: existing?.created_at || getTimestamp(),
        updated_at: getTimestamp(),
    };

    await saveEncryptedAISettings(userId, newSettings);
}

// ============ Templates API ============

export async function getTemplates(userId?: string): Promise<ArticleTemplate[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedTemplates(userId);
}

export async function createTemplate(
    userId: string,
    templateData: Omit<ArticleTemplate, 'id' | 'user_id' | 'created_at' | 'updated_at'>
): Promise<ArticleTemplate> {
    checkEncryptionKey();
    const newTemplate: ArticleTemplate = {
        id: generateId(),
        user_id: userId,
        ...templateData,
        created_at: getTimestamp(),
        updated_at: getTimestamp(),
    };

    await saveEncryptedTemplate(userId, newTemplate);
    return newTemplate;
}

export async function updateTemplate(
    userId: string,
    templateId: string,
    updates: Partial<Omit<ArticleTemplate, 'id' | 'user_id' | 'created_at' | 'updated_at'>>
): Promise<ArticleTemplate> {
    checkEncryptionKey();
    const templates = await getEncryptedTemplates(userId);
    const template = templates.find(t => t.id === templateId);
    if (!template) throw new Error("模板不存在");

    const updatedTemplate: ArticleTemplate = {
        ...template,
        ...updates,
        updated_at: getTimestamp(),
    };

    await saveEncryptedTemplate(userId, updatedTemplate);
    return updatedTemplate;
}

export async function deleteTemplate(userId: string, templateId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedTemplate(userId, templateId);
}

// ============ Keywords API ============

export async function getKeywords(userId?: string): Promise<Keyword[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedKeywords(userId);
}

export async function createKeyword(
    userId: string,
    keywordData: Omit<Keyword, 'id' | 'user_id' | 'created_at'>
): Promise<Keyword> {
    checkEncryptionKey();
    const newKeyword: Keyword = {
        id: generateId(),
        user_id: userId,
        ...keywordData,
        created_at: getTimestamp(),
    };

    await saveEncryptedKeyword(userId, newKeyword);
    return newKeyword;
}

export async function updateKeyword(
    userId: string,
    keywordId: string,
    updates: Partial<Omit<Keyword, 'id' | 'user_id' | 'created_at'>>
): Promise<Keyword> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const keyword = keywords.find(k => k.id === keywordId);
    if (!keyword) throw new Error("关键词不存在");

    const updatedKeyword: Keyword = {
        ...keyword,
        ...updates,
    };

    await saveEncryptedKeyword(userId, updatedKeyword);
    return updatedKeyword;
}

export async function deleteKeyword(userId: string, keywordId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedKeyword(userId, keywordId);
}

// ============ Topics API ============

export async function getTopics(userId?: string): Promise<Topic[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedTopics(userId);
}

export async function createTopic(
    userId: string,
    topicData: Omit<Topic, 'id' | 'user_id' | 'created_at'>
): Promise<Topic> {
    checkEncryptionKey();
    const newTopic: Topic = {
        id: generateId(),
        user_id: userId,
        ...topicData,
        created_at: getTimestamp(),
    };

    await saveEncryptedTopic(userId, newTopic);
    return newTopic;
}

export async function updateTopic(
    userId: string,
    topicId: string,
    updates: Partial<Omit<Topic, 'id' | 'user_id' | 'created_at'>>
): Promise<Topic> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const topic = topics.find(t => t.id === topicId);
    if (!topic) throw new Error("主题不存在");

    const updatedTopic: Topic = {
        ...topic,
        ...updates,
    };

    await saveEncryptedTopic(userId, updatedTopic);
    return updatedTopic;
}

export async function deleteTopic(userId: string, topicId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedTopic(userId, topicId);
}

// ============ Article Versions API ============

export async function getArticleVersions(
    userId: string,
    articleId: string
): Promise<ArticleVersion[]> {
    checkEncryptionKey();
    return await getEncryptedArticleVersions(userId, articleId);
}

export async function createArticleVersion(
    userId: string,
    versionData: Omit<ArticleVersion, 'id' | 'user_id' | 'created_at'>
): Promise<ArticleVersion> {
    checkEncryptionKey();
    const newVersion: ArticleVersion = {
        id: generateId(),
        user_id: userId,
        ...versionData,
        created_at: getTimestamp(),
    };

    await saveEncryptedArticleVersion(userId, newVersion);
    return newVersion;
}

export async function deleteArticleVersion(userId: string, versionId: string): Promise<void> {
    checkEncryptionKey();
    await deleteEncryptedArticleVersion(userId, versionId);
}

// ============ Statistics API ============

export async function getStatistics(userId?: string) {
    checkEncryptionKey();
    if (!userId) {
        return {
            totalSites: 0,
            totalArticles: 0,
            publishedArticles: 0,
            draftArticles: 0,
        };
    }

    const sites = await getEncryptedSites(userId);
    const articles = await getEncryptedArticles(userId);

    const totalSites = sites.length;
    const totalArticles = articles.length;
    const publishedArticles = articles.filter(a => a.status === 'published').length;

    return {
        totalSites,
        totalArticles,
        publishedArticles,
        draftArticles: totalArticles - publishedArticles,
    };
}

// ============ Data Export/Import API ============

export async function exportEncryptedData(userId: string): Promise<{
    version: number;
    timestamp: string;
    data: Record<string, unknown>;
}> {
    checkEncryptionKey();
    return await exportUserData(userId);
}

export async function importEncryptedData(
    userId: string,
    backup: {
        version: number;
        timestamp: string;
        data: Record<string, unknown>;
    }
): Promise<void> {
    checkEncryptionKey();
    await importUserData(userId, backup);
}

export async function clearAllUserData(userId: string): Promise<void> {
    clearUserData(userId);
}
