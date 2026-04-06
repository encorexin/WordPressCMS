// 文章表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Article } from '../../models/Article'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'

export class ArticleDao {
  private static getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

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
        'created_at': article.createdAt,
        'updated_at': article.updatedAt
      }
      await ArticleDao.getStore().insert(DatabaseSchema.TABLE_ARTICLES, bucket)
      return article
    } catch (err) {
      throw new Error(`Failed to insert article: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string, status: string = ''): Promise<Article[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      if (status.length > 0) {
        predicates.equalTo('status', status)
      }
      predicates.orderByDesc('updated_at')
      resultSet = await ArticleDao.getStore().query(predicates)
      const articles: Article[] = []
      while (resultSet.goToNextRow()) {
        articles.push(ArticleDao.fromResultSet(resultSet))
      }
      return articles
    } catch (err) {
      throw new Error(`Failed to find articles by user: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async findById(id: string): Promise<Article | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', id)
      resultSet = await ArticleDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return ArticleDao.fromResultSet(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`Failed to find article by id: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async update(article: Article): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', article.id)
      const bucket: relationalStore.ValuesBucket = {
        'site_id': article.siteId.length > 0 ? article.siteId : null,
        'title': article.title,
        'content': article.content.length > 0 ? article.content : null,
        'keywords': article.keywords.length > 0 ? article.keywords : null,
        'template': article.template.length > 0 ? article.template : null,
        'status': article.status,
        'wordpress_post_id': article.wordpressPostId.length > 0 ? article.wordpressPostId : null,
        'updated_at': getTimestamp()
      }
      await ArticleDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update article: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('id', id)
      await ArticleDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete article: ${String(err)}`)
    }
  }

  static async search(userId: string, query: string): Promise<Article[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      predicates.contains('title', query)
      predicates.orderByDesc('updated_at')
      resultSet = await ArticleDao.getStore().query(predicates)
      const articles: Article[] = []
      while (resultSet.goToNextRow()) {
        articles.push(ArticleDao.fromResultSet(resultSet))
      }
      return articles
    } catch (err) {
      throw new Error(`Failed to search articles: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_ARTICLES)
      predicates.equalTo('user_id', userId)
      resultSet = await ArticleDao.getStore().query(predicates)
      return resultSet.rowCount
    } catch (err) {
      throw new Error(`Failed to count articles: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
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
      article.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      article.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return article
    } catch (err) {
      throw new Error(`Failed to map article result set: ${String(err)}`)
    }
  }
}
