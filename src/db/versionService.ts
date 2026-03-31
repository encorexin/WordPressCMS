import {
  getEncryptedArticleVersions,
  saveEncryptedArticleVersion,
  deleteEncryptedArticleVersion,
  hasEncryptionKey,
} from "./encryptedDatabase";
import { generateId, getTimestamp } from "./database";
import type { ArticleVersion } from "./database";

// 最大保留版本数
const MAX_VERSIONS = 50;

/**
 * 创建文章版本
 */
export async function createArticleVersion(
  articleId: string,
  userId: string,
  data: {
    title: string;
    content: string | null;
    keywords: string | null;
    template: string | null;
  }
): Promise<ArticleVersion> {
  if (!hasEncryptionKey()) {
    throw new Error('未登录或密钥未设置');
  }

  // 获取当前所有版本
  const versions = await getEncryptedArticleVersions(userId, articleId);
  const maxVersion = versions.length > 0
    ? Math.max(...versions.map(v => v.version_number))
    : 0;

  const version: ArticleVersion = {
    id: generateId(),
    article_id: articleId,
    user_id: userId,
    title: data.title,
    content: data.content,
    keywords: data.keywords,
    template: data.template,
    version_number: maxVersion + 1,
    created_at: getTimestamp(),
  };

  await saveEncryptedArticleVersion(userId, version);

  // 清理旧版本
  await cleanupOldVersions(userId, articleId);

  return version;
}

/**
 * 获取文章的所有版本
 */
export async function getArticleVersions(
  userId: string,
  articleId: string
): Promise<ArticleVersion[]> {
  if (!hasEncryptionKey()) {
    throw new Error('未登录或密钥未设置');
  }
  return await getEncryptedArticleVersions(userId, articleId);
}

/**
 * 删除单个版本
 */
export async function deleteArticleVersion(
  userId: string,
  versionId: string
): Promise<void> {
  if (!hasEncryptionKey()) {
    throw new Error('未登录或密钥未设置');
  }
  await deleteEncryptedArticleVersion(userId, versionId);
}

/**
 * 删除文章的所有版本
 */
export async function deleteAllArticleVersions(
  userId: string,
  articleId: string
): Promise<void> {
  if (!hasEncryptionKey()) {
    throw new Error('未登录或密钥未设置');
  }
  const versions = await getEncryptedArticleVersions(userId, articleId);
  for (const version of versions) {
    await deleteEncryptedArticleVersion(userId, version.id);
  }
}

/**
 * 清理旧版本（保留最近 MAX_VERSIONS 个）
 */
async function cleanupOldVersions(
  userId: string,
  articleId: string
): Promise<void> {
  const versions = await getEncryptedArticleVersions(userId, articleId);
  if (versions.length > MAX_VERSIONS) {
    // 按版本号排序，删除旧的
    const sorted = versions.sort((a, b) => a.version_number - b.version_number);
    const toDelete = sorted.slice(0, versions.length - MAX_VERSIONS);
    for (const version of toDelete) {
      await deleteEncryptedArticleVersion(userId, version.id);
    }
  }
}
