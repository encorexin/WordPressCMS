/**
 * 加密数据 API 层
 * 所有数据操作都通过加密存储进行
 */

import { generateId, getTimestamp } from "./models";
import type {
    LocalUser,
    LocalWordPressSite,
    LocalArticle,
    ArticleTemplate,
    Keyword,
    Topic,
} from "./models";
export type { AISettings, ArticleTemplate, Keyword, Topic, ArticleVersion } from "./models";
import {
    getEncryptedArticles,
    saveEncryptedArticle,
    deleteEncryptedArticle,
    getEncryptedArticleById,
    getEncryptedSites,
    saveEncryptedSite,
    deleteEncryptedSite,
    getEncryptedTemplates,
    saveEncryptedTemplate,
    deleteEncryptedTemplate,
    getEncryptedKeywords,
    saveEncryptedKeyword,
    deleteEncryptedKeyword,
    getEncryptedTopics,
    saveEncryptedTopic,
    deleteEncryptedTopic,
    setEncryptedKeywords,
    setEncryptedTopics,
    setEncryptedTemplates,
    exportUserData,
    importUserData,
    clearUserData,
    hasEncryptionKey
} from "./encryptedDatabase";
import { db } from "./database";

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
    const user = await db.users.get(userId);
    return user ?? null;
}

export async function getAllProfiles(): Promise<Profile[]> {
    return await db.users.orderBy('created_at').reverse().toArray();
}

export async function updateProfile(
    userId: string,
    updates: Partial<Profile>
): Promise<Profile> {
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

export const DEFAULT_TEMPLATES = [
    {
        name: '技术教程',
        description: '适用于技术文章、编程教程等',
        system_prompt: `你是一位经验丰富的技术作者，擅长撰写清晰易懂的技术教程。

请根据用户提供的关键词创作一篇技术教程文章：

要求：
1. 使用通俗易懂的语言解释技术概念
2. 包含代码示例（如适用）
3. 分步骤讲解，循序渐进
4. 提供实践建议和注意事项
5. 使用 Markdown 格式，代码块需标注语言
6. 字数 1000-1500 字`,
    },
    {
        name: '产品评测',
        description: '适用于产品介绍、评测类文章',
        system_prompt: `你是一位专业的产品评测作者，擅长客观分析产品优缺点。

请根据用户提供的关键词创作一篇产品评测文章：

要求：
1. 客观公正地分析产品特点
2. 从多个维度评价（功能、性能、价格、用户体验等）
3. 列出产品优点和缺点
4. 与同类产品进行对比（如适用）
5. 给出购买建议
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: 'SEO 文章',
        description: '适用于搜索引擎优化的内容',
        system_prompt: `你是一位 SEO 内容专家，擅长撰写对搜索引擎友好的文章。

请根据用户提供的关键词创作一篇 SEO 优化文章：

要求：
1. 关键词自然融入标题和正文
2. 使用清晰的标题层级（H1、H2、H3）
3. 开头段落包含核心关键词
4. 每个段落聚焦一个主题
5. 适当使用列表和表格
6. 结尾包含 CTA（行动号召）
7. 使用 Markdown 格式
8. 字数 1000-1500 字`,
    },
    {
        name: '新闻稿',
        description: '适用于新闻报道、公告类文章',
        system_prompt: `你是一位专业的新闻编辑，擅长撰写客观准确的新闻稿。

请根据用户提供的关键词创作一篇新闻稿：

要求：
1. 遵循新闻写作规范（倒金字塔结构）
2. 开头概括核心内容（5W1H）
3. 语言客观、准确、简洁
4. 引用相关数据和事实
5. 保持中立立场
6. 使用 Markdown 格式
7. 字数 500-800 字`,
    },
    {
        name: '博客文章',
        description: '适用于个人博客、生活分享',
        system_prompt: `你是一位有亲和力的博客作者，擅长用轻松的语气分享见解。

请根据用户提供的关键词创作一篇博客文章：

要求：
1. 语气亲切、自然，像与朋友对话
2. 融入个人观点和感受
3. 使用生动的比喻和例子
4. 段落简短，易于阅读
5. 可以适当使用表情符号
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: '操作指南',
        description: '适用于步骤教程、使用说明',
        system_prompt: `你是一位技术文档专家，擅长撰写清晰的操作指南。

请根据用户提供的关键词创作一篇操作指南：

要求：
1. 使用编号列表，步骤清晰
2. 每个步骤独立、具体、可执行
3. 包含必要的前置条件和注意事项
4. 适当配合说明性文字
5. 使用 Markdown 格式
6. 字数 600-1000 字`,
    },
    {
        name: '清单文章',
        description: '适用于 Top 10、盘点类文章',
        system_prompt: `你是一位内容策划专家，擅长撰写引人入胜的清单类文章。

请根据用户提供的关键词创作一篇清单文章：

要求：
1. 标题吸引眼球（如"10个必知的..."）
2. 每个条目独立成段，有小标题
3. 内容多样，覆盖不同角度
4. 提供实用价值
5. 结尾有总结
6. 使用 Markdown 格式
7. 字数 1000-1500 字`,
    },
    {
        name: '品牌故事',
        description: '适用于企业介绍、品牌宣传',
        system_prompt: `你是一位品牌文案专家，擅长讲述动人的品牌故事。

请根据用户提供的关键词创作一篇品牌故事：

要求：
1. 突出品牌理念和价值观
2. 融入创始故事或发展历程
3. 情感共鸣，建立连接
4. 突出差异化优势
5. 结尾有行动号召
6. 使用 Markdown 格式
7. 字数 600-1000 字`,
    },
    {
        name: '知识科普',
        description: '适用于科普解读、知识分享',
        system_prompt: `你是一位知识传播专家，擅长将复杂概念用简单语言解释。

请根据用户提供的关键词创作一篇知识科普文章：

要求：
1. 从基础概念讲起
2. 使用通俗比喻帮助理解
3. 循序渐进，层层深入
4. 举例说明，贴近生活
5. 总结要点，加深记忆
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
    },
    {
        name: '社媒文案',
        description: '适用于微信公众号、社交媒体',
        system_prompt: `你是一位社交媒体运营专家，擅长撰写吸引眼球的社媒文案。

请根据用户提供的关键词创作一篇社媒文案：

要求：
1. 开头抓住注意力（钩子文案）
2. 语言简洁有力，金句频出
3. 段落短小，适合手机阅读
4. 善用分隔符和留白
5. 结尾引导互动或行动
6. 使用 Markdown 格式
7. 字数 500-800 字`,
    },
];

export async function initDefaultTemplates(userId: string): Promise<void> {
    checkEncryptionKey();
    const existingTemplates = await getTemplates(userId);
    const existingNames = new Set(existingTemplates.map(t => t.name));

    for (const template of DEFAULT_TEMPLATES) {
        if (!existingNames.has(template.name)) {
            await createTemplate(userId, template);
        }
    }
}

export async function cleanDuplicateTemplates(userId: string): Promise<number> {
    checkEncryptionKey();
    const templates = await getTemplates(userId);

    const sorted = [...templates].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime());
    const seen = new Set<string>();
    const kept: ArticleTemplate[] = [];
    let deletedCount = 0;

    for (const template of sorted) {
        if (seen.has(template.name)) {
            deletedCount++;
            continue;
        }
        seen.add(template.name);
        kept.push(template);
    }

    if (deletedCount > 0) {
        await setEncryptedTemplates(userId, kept);
    }

    return deletedCount;
}

// ============ Keywords API ============

export async function getKeywords(userId?: string): Promise<Keyword[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedKeywords(userId);
}

export async function createKeyword(
    userId: string,
    keywordData: { keyword: string; group_name?: string; use_count?: number }
): Promise<Keyword> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const exists = keywords.some(k => k.keyword === keywordData.keyword);
    if (exists) {
        throw new Error('关键词已存在');
    }
    const newKeyword: Keyword = {
        id: generateId(),
        user_id: userId,
        keyword: keywordData.keyword,
        group_name: keywordData.group_name || '未分组',
        use_count: keywordData.use_count ?? 0,
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

export async function getKeywordsByGroup(userId: string): Promise<Record<string, Keyword[]>> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const grouped: Record<string, Keyword[]> = {};

    for (const kw of keywords) {
        const group = kw.group_name || '未分组';
        if (!grouped[group]) {
            grouped[group] = [];
        }
        grouped[group].push(kw);
    }

    return grouped;
}

export async function getGroups(userId: string): Promise<string[]> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const groups = new Set<string>();

    for (const kw of keywords) {
        groups.add(kw.group_name || '未分组');
    }

    return Array.from(groups);
}

export async function createKeywordsBatch(
    userId: string,
    keywords: string[],
    groupName: string = '未分组'
): Promise<{ created: number; skipped: number }> {
    checkEncryptionKey();
    const existing = await getEncryptedKeywords(userId);
    const existingSet = new Set(existing.map(k => k.keyword));

    let created = 0;
    let skipped = 0;
    const now = getTimestamp();

    const toAdd: Keyword[] = [];
    for (const kw of keywords) {
        const trimmed = kw.trim();
        if (!trimmed) continue;
        if (existingSet.has(trimmed)) {
            skipped++;
            continue;
        }
        existingSet.add(trimmed);
        created++;
        toAdd.push({
            id: generateId(),
            user_id: userId,
            keyword: trimmed,
            group_name: groupName || '未分组',
            use_count: 0,
            created_at: now,
        });
    }

    if (toAdd.length > 0) {
        await setEncryptedKeywords(userId, [...existing, ...toAdd]);
    }

    return { created, skipped };
}

export async function deleteKeywordsByGroup(userId: string, groupName: string): Promise<number> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const toDeleteCount = keywords.filter(kw => (kw.group_name || '未分组') === groupName).length;
    if (toDeleteCount === 0) {
        return 0;
    }
    const kept = keywords.filter(kw => (kw.group_name || '未分组') !== groupName);
    await setEncryptedKeywords(userId, kept);
    return toDeleteCount;
}

export async function incrementKeywordUsage(userId: string, keywordId: string): Promise<void> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const target = keywords.find(k => k.id === keywordId);
    if (!target) return;
    const next = keywords.map(k => (k.id === keywordId ? { ...k, use_count: k.use_count + 1 } : k));
    await setEncryptedKeywords(userId, next);
}

export async function searchKeywords(userId: string, query: string): Promise<Keyword[]> {
    checkEncryptionKey();
    const keywords = await getEncryptedKeywords(userId);
    const lowerQuery = query.toLowerCase();
    return keywords.filter(kw => kw.keyword.toLowerCase().includes(lowerQuery));
}

// ============ Topics API ============

export async function getTopics(userId?: string): Promise<Topic[]> {
    checkEncryptionKey();
    if (!userId) return [];
    return await getEncryptedTopics(userId);
}

export async function createTopic(
    userId: string,
    topicData: { title: string; description: string; keywords: string; category: string; used?: boolean }
): Promise<Topic> {
    checkEncryptionKey();
    const newTopic: Topic = {
        id: generateId(),
        user_id: userId,
        title: topicData.title,
        description: topicData.description,
        keywords: topicData.keywords,
        category: topicData.category || '未分类',
        used: topicData.used ?? false,
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

export async function getUnusedTopics(userId: string): Promise<Topic[]> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    return topics.filter(t => !t.used);
}

export async function getTopicsByCategory(userId: string): Promise<Record<string, Topic[]>> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const grouped: Record<string, Topic[]> = {};

    for (const topic of topics) {
        const category = topic.category || '未分类';
        if (!grouped[category]) {
            grouped[category] = [];
        }
        grouped[category].push(topic);
    }

    return grouped;
}

export async function createTopicsBatch(
    userId: string,
    topics: { title: string; description: string; keywords: string; category: string }[]
): Promise<number> {
    checkEncryptionKey();
    const existing = await getEncryptedTopics(userId);
    let created = 0;
    const now = getTimestamp();
    const toAdd: Topic[] = [];

    for (const data of topics) {
        if (!data.title.trim()) {
            continue;
        }
        created++;
        toAdd.push({
            id: generateId(),
            user_id: userId,
            title: data.title,
            description: data.description,
            keywords: data.keywords,
            category: data.category || '未分类',
            used: false,
            created_at: now,
        });
    }

    if (toAdd.length > 0) {
        await setEncryptedTopics(userId, [...existing, ...toAdd]);
    }

    return created;
}

export async function markTopicAsUsed(userId: string, topicId: string): Promise<void> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const next = topics.map(t => (t.id === topicId ? { ...t, used: true } : t));
    await setEncryptedTopics(userId, next);
}

export async function deleteUsedTopics(userId: string): Promise<number> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const usedCount = topics.filter(t => t.used).length;
    if (usedCount === 0) {
        return 0;
    }
    const kept = topics.filter(t => !t.used);
    await setEncryptedTopics(userId, kept);
    return usedCount;
}

export async function getCategories(userId: string): Promise<string[]> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const categories = new Set<string>();

    for (const topic of topics) {
        categories.add(topic.category || '未分类');
    }

    return Array.from(categories);
}

export async function searchTopics(userId: string, query: string): Promise<Topic[]> {
    checkEncryptionKey();
    const topics = await getEncryptedTopics(userId);
    const lowerQuery = query.toLowerCase();
    return topics.filter(topic =>
        topic.title.toLowerCase().includes(lowerQuery) ||
        topic.description.toLowerCase().includes(lowerQuery) ||
        topic.keywords.toLowerCase().includes(lowerQuery)
    );
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
