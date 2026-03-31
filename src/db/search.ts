import { db } from "./database";
import type { LocalArticle, Keyword, ArticleTemplate, Topic } from "./database";

// 搜索结果类型
export interface SearchResult {
  id: string;
  type: "article" | "keyword" | "template" | "topic";
  title: string;
  subtitle?: string;
  path: string;
}

// 搜索选项
export interface SearchOptions {
  userId?: string;
  limit?: number;
}

/**
 * 全局搜索 - 搜索文章、关键词、模板、主题
 */
export async function globalSearch(
  query: string,
  options: SearchOptions = {}
): Promise<SearchResult[]> {
  const { userId, limit = 20 } = options;
  const searchTerm = query.toLowerCase().trim();

  if (!searchTerm) {
    return [];
  }

  const results: SearchResult[] = [];

  // 搜索文章
  const articles = await searchArticles(searchTerm, userId);
  results.push(...articles);

  // 搜索关键词
  const keywords = await searchKeywords(searchTerm, userId);
  results.push(...keywords);

  // 搜索模板
  const templates = await searchTemplates(searchTerm, userId);
  results.push(...templates);

  // 搜索主题
  const topics = await searchTopics(searchTerm, userId);
  results.push(...topics);

  // 按相关性排序并限制数量
  return results.slice(0, limit);
}

/**
 * 搜索文章
 */
async function searchArticles(
  searchTerm: string,
  userId?: string
): Promise<SearchResult[]> {
  let articles: LocalArticle[];

  if (userId) {
    articles = await db.articles
      .where("user_id")
      .equals(userId)
      .filter(
        (a) =>
          a.title.toLowerCase().includes(searchTerm) ||
          (a.content?.toLowerCase().includes(searchTerm) ?? false) ||
          (a.keywords?.toLowerCase().includes(searchTerm) ?? false)
      )
      .limit(10)
      .toArray();
  } else {
    articles = await db.articles
      .filter(
        (a) =>
          a.title.toLowerCase().includes(searchTerm) ||
          (a.content?.toLowerCase().includes(searchTerm) ?? false) ||
          (a.keywords?.toLowerCase().includes(searchTerm) ?? false)
      )
      .limit(10)
      .toArray();
  }

  return articles.map((article) => ({
    id: article.id,
    type: "article",
    title: article.title,
    subtitle: article.status === "published" ? "已发布" : "草稿",
    path: `/articles/${article.id}`,
  }));
}

/**
 * 搜索关键词
 */
async function searchKeywords(
  searchTerm: string,
  userId?: string
): Promise<SearchResult[]> {
  let keywords: Keyword[];

  if (userId) {
    keywords = await db.keywords
      .where("user_id")
      .equals(userId)
      .filter((k) => k.keyword.toLowerCase().includes(searchTerm))
      .limit(5)
      .toArray();
  } else {
    keywords = await db.keywords
      .filter((k) => k.keyword.toLowerCase().includes(searchTerm))
      .limit(5)
      .toArray();
  }

  return keywords.map((keyword) => ({
    id: keyword.id,
    type: "keyword",
    title: keyword.keyword,
    subtitle: keyword.group_name || "未分组",
    path: "/keywords",
  }));
}

/**
 * 搜索模板
 */
async function searchTemplates(
  searchTerm: string,
  userId?: string
): Promise<SearchResult[]> {
  let templates: ArticleTemplate[];

  if (userId) {
    templates = await db.article_templates
      .where("user_id")
      .equals(userId)
      .filter(
        (t) =>
          t.name.toLowerCase().includes(searchTerm) ||
          t.description.toLowerCase().includes(searchTerm)
      )
      .limit(5)
      .toArray();
  } else {
    templates = await db.article_templates
      .filter(
        (t) =>
          t.name.toLowerCase().includes(searchTerm) ||
          t.description.toLowerCase().includes(searchTerm)
      )
      .limit(5)
      .toArray();
  }

  return templates.map((template) => ({
    id: template.id,
    type: "template",
    title: template.name,
    subtitle: template.description?.slice(0, 50) || "无描述",
    path: "/templates",
  }));
}

/**
 * 搜索主题
 */
async function searchTopics(
  searchTerm: string,
  userId?: string
): Promise<SearchResult[]> {
  let topics: Topic[];

  if (userId) {
    topics = await db.topics
      .where("user_id")
      .equals(userId)
      .filter(
        (t) =>
          t.title.toLowerCase().includes(searchTerm) ||
          t.description.toLowerCase().includes(searchTerm) ||
          t.keywords.toLowerCase().includes(searchTerm)
      )
      .limit(5)
      .toArray();
  } else {
    topics = await db.topics
      .filter(
        (t) =>
          t.title.toLowerCase().includes(searchTerm) ||
          t.description.toLowerCase().includes(searchTerm) ||
          t.keywords.toLowerCase().includes(searchTerm)
      )
      .limit(5)
      .toArray();
  }

  return topics.map((topic) => ({
    id: topic.id,
    type: "topic",
    title: topic.title,
    subtitle: topic.category || "未分类",
    path: "/topics",
  }));
}

/**
 * 获取类型图标和标签
 */
export function getSearchTypeInfo(type: SearchResult["type"]) {
  const info = {
    article: {
      label: "文章",
      icon: "FileText",
      color: "text-blue-600 dark:text-blue-400",
      bgColor: "bg-blue-50 dark:bg-blue-950/50",
    },
    keyword: {
      label: "关键词",
      icon: "Tag",
      color: "text-green-600 dark:text-green-400",
      bgColor: "bg-green-50 dark:bg-green-950/50",
    },
    template: {
      label: "模板",
      icon: "Layout",
      color: "text-purple-600 dark:text-purple-400",
      bgColor: "bg-purple-50 dark:bg-purple-950/50",
    },
    topic: {
      label: "主题",
      icon: "Lightbulb",
      color: "text-orange-600 dark:text-orange-400",
      bgColor: "bg-orange-50 dark:bg-orange-950/50",
    },
  };

  return info[type];
}
