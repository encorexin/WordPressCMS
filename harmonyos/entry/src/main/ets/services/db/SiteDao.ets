// 站点表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { WordPressSite } from '../../models/WordPressSite'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { CryptoService } from '../crypto/CryptoService'
import { BaseDao } from './BaseDao'

export class SiteDao {
  private static readonly baseDao: BaseDao<WordPressSite> =
    new BaseDao<WordPressSite>(DatabaseSchema.TABLE_SITES, SiteDao.syncFromResultSet)

  static async insert(userId: string, siteName: string, siteUrl: string,
    username: string, appPassword: string): Promise<WordPressSite> {
    try {
      const now = getTimestamp()
      const site = new WordPressSite()
      site.id = generateId()
      site.userId = userId
      site.siteName = siteName
      site.siteUrl = siteUrl
      site.username = username
      site.appPassword = appPassword
      site.status = 'active'
      site.createdAt = now
      site.updatedAt = now

      const encryptedPassword = await CryptoService.encryptField(site.appPassword)

      const bucket: relationalStore.ValuesBucket = {
        'id': site.id,
        'user_id': site.userId,
        'site_name': site.siteName,
        'site_url': site.siteUrl,
        'username': site.username,
        'app_password': encryptedPassword,
        'status': site.status,
        'created_at': site.createdAt,
        'updated_at': site.updatedAt
      }
      await SiteDao.baseDao.getStore().insert(DatabaseSchema.TABLE_SITES, bucket)
      return site
    } catch (err) {
      throw new Error(`Failed to insert site: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<WordPressSite[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('created_at')
      return await SiteDao.baseDao.queryListAsync(predicates, 'SiteDao.findByUserId', SiteDao.fromResultSet)
    } catch (err) {
      throw new Error(`Failed to find sites by user: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<WordPressSite | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', id)
      return await SiteDao.baseDao.queryFirstAsync(predicates, 'SiteDao.findById', SiteDao.fromResultSet)
    } catch (err) {
      throw new Error(`Failed to find site by id: ${String(err)}`)
    }
  }

  static async update(site: WordPressSite): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', site.id)
      const encryptedPassword = await CryptoService.encryptField(site.appPassword)
      const bucket: relationalStore.ValuesBucket = {
        'site_name': site.siteName,
        'site_url': site.siteUrl,
        'username': site.username,
        'app_password': encryptedPassword,
        'status': site.status,
        'updated_at': getTimestamp()
      }
      await SiteDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update site: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', id)
      await SiteDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete site: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('user_id', userId)
      return await SiteDao.baseDao.count(predicates, 'SiteDao.countByUserId')
    } catch (err) {
      throw new Error(`Failed to count sites: ${String(err)}`)
    }
  }

  /** 同步映射 — 供 BaseDao 构造函数使用（不支持解密，仅 count 等 SQL 聚合场景） */
  private static syncFromResultSet(_rs: relationalStore.ResultSet): WordPressSite {
    // SiteDao 的完整映射需要异步解密，此处仅作 BaseDao 占位
    const site = new WordPressSite()
    return site
  }

  /** 异步映射 — 支持加密字段解密 */
  static async fromResultSet(rs: relationalStore.ResultSet): Promise<WordPressSite> {
    try {
      const site = new WordPressSite()
      site.id = rs.getString(rs.getColumnIndex('id'))
      site.userId = rs.getString(rs.getColumnIndex('user_id'))
      site.siteName = rs.getString(rs.getColumnIndex('site_name'))
      site.siteUrl = rs.getString(rs.getColumnIndex('site_url'))
      site.username = rs.getString(rs.getColumnIndex('username'))
      const storedPassword = rs.getString(rs.getColumnIndex('app_password'))
      site.appPassword = await CryptoService.decryptField(storedPassword)
      site.status = rs.getString(rs.getColumnIndex('status'))
      site.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      site.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return site
    } catch (err) {
      throw new Error(`Failed to map site result set: ${String(err)}`)
    }
  }
}
