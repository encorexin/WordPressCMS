// 文章版本表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { ArticleVersion } from '../../models/ArticleVersion'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'

export class VersionDao {
  private static getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  static async insert(articleId: string, userId: string, siteId: string,
    title: string, content: string, keywords: string, template: string,
    wordpressPostId: string, status: string, versionNumber: number): Promise<ArticleVersion> {
    try {
      const version = new ArticleVersion()
      version.id = generateId()
      version.articleId = articleId
      version.userId = userId
      version.siteId = siteId
      version.title = title
      version.content = content
      version.keywords = keywords
      version.template = template
      version.wordpressPostId = wordpressPostId
      version.status = status.length > 0 ? status : 'draft'
      version.versionNumber = versionNumber
      version.createdAt = getTimestamp()

      const bucket: relationalStore.ValuesBucket = {
        'id': version.id,
        'article_id': version.articleId,
        'user_id': version.userId,
        'site_id': version.siteId.length > 0 ? version.siteId : null,
        'title': version.title,
        'content': version.content.length > 0 ? version.content : null,
        'keywords': version.keywords.length > 0 ? version.keywords : null,
        'template': version.template.length > 0 ? version.template : null,
        'wordpress_post_id': version.wordpressPostId.length > 0 ? version.wordpressPostId : null,
        'status': version.status,
        'version_number': version.versionNumber,
        'created_at': version.createdAt
      }
      await VersionDao.getStore().insert(DatabaseSchema.TABLE_VERSIONS, bucket)
      return version
    } catch (err) {
      throw new Error(`Failed to insert version: ${String(err)}`)
    }
  }

  static async findByArticleId(articleId: string): Promise<ArticleVersion[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_VERSIONS)
      predicates.equalTo('article_id', articleId)
      predicates.orderByDesc('version_number')
      resultSet = await VersionDao.getStore().query(predicates)
      const list: ArticleVersion[] = []
      while (resultSet.goToNextRow()) {
        list.push(VersionDao.fromResultSet(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`Failed to find versions by article: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async findById(id: string): Promise<ArticleVersion | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_VERSIONS)
      predicates.equalTo('id', id)
      resultSet = await VersionDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return VersionDao.fromResultSet(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`Failed to find version by id: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async getNextVersionNumber(articleId: string): Promise<number> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_VERSIONS)
      predicates.equalTo('article_id', articleId)
      predicates.orderByDesc('version_number')
      predicates.limitAs(1)
      resultSet = await VersionDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        const current = resultSet.getLong(resultSet.getColumnIndex('version_number'))
        return current + 1
      }
      return 1
    } catch (err) {
      throw new Error(`Failed to get next version number: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_VERSIONS)
      predicates.equalTo('id', id)
      await VersionDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete version by id: ${String(err)}`)
    }
  }

  static async deleteByArticleId(articleId: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_VERSIONS)
      predicates.equalTo('article_id', articleId)
      await VersionDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete versions by article: ${String(err)}`)
    }
  }

  private static fromResultSet(rs: relationalStore.ResultSet): ArticleVersion {
    try {
      const v = new ArticleVersion()
      v.id = rs.getString(rs.getColumnIndex('id'))
      v.articleId = rs.getString(rs.getColumnIndex('article_id'))
      v.userId = rs.getString(rs.getColumnIndex('user_id'))
      v.siteId = rs.isColumnNull(rs.getColumnIndex('site_id')) ? '' : rs.getString(rs.getColumnIndex('site_id'))
      v.title = rs.isColumnNull(rs.getColumnIndex('title')) ? '' : rs.getString(rs.getColumnIndex('title'))
      v.content = rs.isColumnNull(rs.getColumnIndex('content')) ? '' : rs.getString(rs.getColumnIndex('content'))
      v.keywords = rs.isColumnNull(rs.getColumnIndex('keywords')) ? '' : rs.getString(rs.getColumnIndex('keywords'))
      v.template = rs.isColumnNull(rs.getColumnIndex('template')) ? '' : rs.getString(rs.getColumnIndex('template'))
      v.wordpressPostId = rs.isColumnNull(rs.getColumnIndex('wordpress_post_id')) ? '' : rs.getString(rs.getColumnIndex('wordpress_post_id'))
      v.status = rs.isColumnNull(rs.getColumnIndex('status')) ? 'draft' : rs.getString(rs.getColumnIndex('status'))
      v.versionNumber = rs.getLong(rs.getColumnIndex('version_number'))
      v.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      return v
    } catch (err) {
      throw new Error(`Failed to map version result set: ${String(err)}`)
    }
  }
}
