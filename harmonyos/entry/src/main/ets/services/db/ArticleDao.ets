// 文章表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Article } from '../../models/Article'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { Logger } from '../../utils/Logger'
import { ContentMetrics } from '../../utils/ContentMetrics'
import { BaseDao } from './BaseDao'

export class ArticleDao {
  private static readonly baseDao: BaseDao<Article> =
    new BaseDao<Article>(DatabaseSchema.TABLE_ARTICLES, ArticleDao.fromResultSet)

  static async insert(userId: string, title: string, siteId: string = '', content: string = '',
    keywords: string = '', template: string = '', wordpressPostId: string = '',
    status: string = 'draft'): Promise<Article> {
    try {
      const now = getTimestamp()
      const article = new Article()
      article.id = generateId()
      article.userId = userId
      article.siteId = siteId
      article.title = title
      article.content = content
      article.keywords = keywords
      article.template = template
      article.status = status.length > 0 ? status : 'draft'
      article.wordpressPostId = wordpressPostId
      article.wordCount = ContentMetrics.countWords(article.content)
      article.tokensUsed = 0
      article.createdAt = now
      article.updatedAt = now

      const bucket: relationalStore.ValuesBucket = {
        'id': article.id,
        'user_id': article.userId,
        'site_id': article.siteId.length > 0 ? article.siteId : null,
        'title': article.title,
        'content': article.content.length > 0 ? article.content : null,
        'keywords': article.keywords.length > 0 ? article.keywords : null,
        'template': article.template.length > 0 ? article.template : null,
        'status': article.status,
        'wordpress_post_id': article.wordpressPostId.length > 0 ? article.wordpressPostId : null,
        'word_count': article.wordCount,
        'tokens_used': article.tokensUsed,
        'created_at': article.createdAt,
        'updated_at': article.updatedAt
      }
      await ArticleDao.baseDao.getStore().insert(DatabaseSchema.TABLE_ARTICLES, bucket)
      return article
    } catch (err) {
      throw new Error(`Failed to insert article: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string, status: string = ''): Promise<Article[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      if (status.length > 0) {
        predicates.equalTo('status', status)
      }
      predicates.orderByDesc('updated_at')
      return await ArticleDao.baseDao.queryList(predicates, 'ArticleDao.findByUserId')
    } catch (err) {
      throw new Error(`Failed to find articles by user: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<Article | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', id)
      return await ArticleDao.baseDao.queryFirst(predicates, 'ArticleDao.findById')
    } catch (err) {
      throw new Error(`Failed to find article by id: ${String(err)}`)
    }
  }

  static async update(article: Article): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', article.id)
      const wordCount = ContentMetrics.countWords(article.content)
      const bucket: relationalStore.ValuesBucket = {
        'site_id': article.siteId.length > 0 ? article.siteId : null,
        'title': article.title,
        'content': article.content.length > 0 ? article.content : null,
        'keywords': article.keywords.length > 0 ? article.keywords : null,
        'template': article.template.length > 0 ? article.template : null,
        'status': article.status,
        'wordpress_post_id': article.wordpressPostId.length > 0 ? article.wordpressPostId : null,
        'word_count': wordCount,
        'tokens_used': article.tokensUsed,
        'updated_at': getTimestamp()
      }
      await ArticleDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update article: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', id)
      await ArticleDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete article: ${String(err)}`)
    }
  }

  static async search(userId: string, query: string): Promise<Article[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      predicates.contains('title', query)
      predicates.orderByDesc('updated_at')
      return await ArticleDao.baseDao.queryList(predicates, 'ArticleDao.search')
    } catch (err) {
      throw new Error(`Failed to search articles: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      return await ArticleDao.baseDao.count(predicates, 'ArticleDao.countByUserId')
    } catch (err) {
      throw new Error(`Failed to count articles: ${String(err)}`)
    }
  }

  static async countByUserIdAndStatus(userId: string, status: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      predicates.equalTo('status', status)
      return await ArticleDao.baseDao.count(predicates, 'ArticleDao.countByUserIdAndStatus')
    } catch (err) {
      throw new Error(`Failed to count articles by status: ${String(err)}`)
    }
  }

  private static fromResultSet(rs: relationalStore.ResultSet): Article {
    try {
      const article = new Article()
      article.id = rs.getString(rs.getColumnIndex('id'))
      article.userId = rs.getString(rs.getColumnIndex('user_id'))
      article.siteId = rs.isColumnNull(rs.getColumnIndex('site_id')) ? '' : rs.getString(rs.getColumnIndex('site_id'))
      article.title = rs.getString(rs.getColumnIndex('title'))
      article.content = rs.isColumnNull(rs.getColumnIndex('content')) ? '' : rs.getString(rs.getColumnIndex('content'))
      article.keywords = rs.isColumnNull(rs.getColumnIndex('keywords')) ? '' : rs.getString(rs.getColumnIndex('keywords'))
      article.template = rs.isColumnNull(rs.getColumnIndex('template')) ? '' : rs.getString(rs.getColumnIndex('template'))
      article.status = rs.getString(rs.getColumnIndex('status'))
      article.wordpressPostId = rs.isColumnNull(rs.getColumnIndex('wordpress_post_id')) ? '' : rs.getString(rs.getColumnIndex('wordpress_post_id'))
      try {
        const wcIndex = rs.getColumnIndex('word_count')
        article.wordCount = rs.isColumnNull(wcIndex) ? 0 : rs.getLong(wcIndex)
      } catch (wordCountErr) {
        Logger.debug('ArticleDao.fromResultSet word_count fallback: %{public}s', String(wordCountErr))
        article.wordCount = 0
      }
      try {
        const tkIndex = rs.getColumnIndex('tokens_used')
        article.tokensUsed = rs.isColumnNull(tkIndex) ? 0 : rs.getLong(tkIndex)
      } catch (tokensErr) {
        Logger.debug('ArticleDao.fromResultSet tokens_used fallback: %{public}s', String(tokensErr))
        article.tokensUsed = 0
      }
      if (article.wordCount <= 0 && article.content.length > 0) {
        article.wordCount = ContentMetrics.countWords(article.content)
      }
      article.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      article.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return article
    } catch (err) {
      throw new Error(`Failed to map article result set: ${String(err)}`)
    }
  }
}
