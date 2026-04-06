// 站点表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { WordPressSite } from '../../models/WordPressSite'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { CryptoService } from '../crypto/CryptoService'

export class SiteDao {
  private static getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

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

      const encryptedPassword = await CryptoService.encrypt(site.appPassword)

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
      await SiteDao.getStore().insert(DatabaseSchema.TABLE_SITES, bucket)
      return site
    } catch (err) {
      throw new Error(`Failed to insert site: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<WordPressSite[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('created_at')
      resultSet = await SiteDao.getStore().query(predicates)
      const sites: WordPressSite[] = []
      while (resultSet.goToNextRow()) {
        sites.push(await SiteDao.fromResultSet(resultSet))
      }
      return sites
    } catch (err) {
      throw new Error(`Failed to find sites by user: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async findById(id: string): Promise<WordPressSite | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', id)
      resultSet = await SiteDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return await SiteDao.fromResultSet(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`Failed to find site by id: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async update(site: WordPressSite): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', site.id)
      const encryptedPassword = await CryptoService.encrypt(site.appPassword)
      const bucket: relationalStore.ValuesBucket = {
        'site_name': site.siteName,
        'site_url': site.siteUrl,
        'username': site.username,
        'app_password': encryptedPassword,
        'status': site.status,
        'updated_at': getTimestamp()
      }
      await SiteDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update site: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('id', id)
      await SiteDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete site: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SITES)
      predicates.equalTo('user_id', userId)
      resultSet = await SiteDao.getStore().query(predicates)
      return resultSet.rowCount
    } catch (err) {
      throw new Error(`Failed to count sites: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  private static async fromResultSet(rs: relationalStore.ResultSet): Promise<WordPressSite> {
    try {
      const site = new WordPressSite()
      site.id = rs.getString(rs.getColumnIndex('id'))
      site.userId = rs.getString(rs.getColumnIndex('user_id'))
      site.siteName = rs.getString(rs.getColumnIndex('site_name'))
      site.siteUrl = rs.getString(rs.getColumnIndex('site_url'))
      site.username = rs.getString(rs.getColumnIndex('username'))
      const storedPassword = rs.getString(rs.getColumnIndex('app_password'))
      site.appPassword = CryptoService.isEncrypted(storedPassword)
        ? await CryptoService.decrypt(storedPassword)
        : storedPassword
      site.status = rs.getString(rs.getColumnIndex('status'))
      site.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      site.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return site
    } catch (err) {
      throw new Error(`Failed to map site result set: ${String(err)}`)
    }
  }
}
