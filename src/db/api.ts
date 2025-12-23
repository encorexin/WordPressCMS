import { db, generateId, getTimestamp, type LocalUser, type LocalWordPressSite, type LocalArticle } from "./database";

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

// ============ Profiles API ============

export async function getProfile(userId: string): Promise<Profile | null> {
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
  if (userId) {
    return await db.wordpress_sites
      .where('user_id')
      .equals(userId)
      .reverse()
      .sortBy('created_at');
  }
  return await db.wordpress_sites.orderBy('created_at').reverse().toArray();
}

export async function getWordPressSite(
  siteId: string
): Promise<WordPressSite | null> {
  const site = await db.wordpress_sites.get(siteId);
  return site ?? null;
}

export async function createWordPressSite(
  userId: string,
  siteData: WordPressSiteInput
): Promise<WordPressSite> {
  const newSite: WordPressSite = {
    id: generateId(),
    user_id: userId,
    ...siteData,
    status: "active",
    created_at: getTimestamp(),
    updated_at: getTimestamp(),
  };

  await db.wordpress_sites.add(newSite);
  return newSite;
}

export async function updateWordPressSite(
  siteId: string,
  updates: Partial<WordPressSiteInput>
): Promise<WordPressSite> {
  await db.wordpress_sites.update(siteId, {
    ...updates,
    updated_at: getTimestamp(),
  });

  const updated = await db.wordpress_sites.get(siteId);
  if (!updated) throw new Error("更新失败");
  return updated;
}

export async function deleteWordPressSite(siteId: string): Promise<void> {
  await db.wordpress_sites.delete(siteId);
}

export async function updateSiteStatus(
  siteId: string,
  status: string
): Promise<void> {
  await db.wordpress_sites.update(siteId, {
    status,
    updated_at: getTimestamp(),
  });
}

// ============ Articles API ============

export async function getArticles(userId?: string): Promise<ArticleWithSite[]> {
  let articles: Article[];

  if (userId) {
    articles = await db.articles
      .where('user_id')
      .equals(userId)
      .reverse()
      .sortBy('created_at');
  } else {
    articles = await db.articles.orderBy('created_at').reverse().toArray();
  }

  // 获取关联的站点信息
  const articlesWithSite: ArticleWithSite[] = await Promise.all(
    articles.map(async (article) => {
      let site: WordPressSite | undefined;
      if (article.site_id) {
        const foundSite = await db.wordpress_sites.get(article.site_id);
        site = foundSite ?? undefined;
      }
      return { ...article, site };
    })
  );

  return articlesWithSite;
}

export async function getArticle(articleId: string): Promise<Article | null> {
  const article = await db.articles.get(articleId);
  return article ?? null;
}

export async function createArticle(
  userId: string,
  articleData: ArticleInput
): Promise<Article> {
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

  await db.articles.add(newArticle);
  return newArticle;
}

export async function updateArticle(
  articleId: string,
  updates: Partial<ArticleInput>
): Promise<Article> {
  await db.articles.update(articleId, {
    ...updates,
    updated_at: getTimestamp(),
  });

  const updated = await db.articles.get(articleId);
  if (!updated) throw new Error("更新失败");
  return updated;
}

export async function deleteArticle(articleId: string): Promise<void> {
  await db.articles.delete(articleId);
}

export async function updateArticleStatus(
  articleId: string,
  status: string,
  wordpressPostId?: string
): Promise<void> {
  const updates: Partial<Article> = {
    status,
    updated_at: getTimestamp(),
  };

  if (wordpressPostId) {
    updates.wordpress_post_id = wordpressPostId;
  }

  await db.articles.update(articleId, updates);
}

// ============ Statistics API ============

export async function getStatistics(userId?: string) {
  let totalSites: number;
  let totalArticles: number;
  let publishedArticles: number;

  if (userId) {
    totalSites = await db.wordpress_sites.where('user_id').equals(userId).count();
    totalArticles = await db.articles.where('user_id').equals(userId).count();
    publishedArticles = await db.articles
      .where('user_id')
      .equals(userId)
      .filter(a => a.status === 'published')
      .count();
  } else {
    totalSites = await db.wordpress_sites.count();
    totalArticles = await db.articles.count();
    publishedArticles = await db.articles.filter(a => a.status === 'published').count();
  }

  return {
    totalSites,
    totalArticles,
    publishedArticles,
    draftArticles: totalArticles - publishedArticles,
  };
}
