// 关键词表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Keyword } from '../../models/Keyword'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { Logger } from '../../utils/Logger'
import { BaseDao } from './BaseDao'

export class KeywordDao {
  private static readonly baseDao: BaseDao<Keyword> = new BaseDao<Keyword>(DatabaseSchema.TABLE_KEYWORDS, KeywordDao.fromResultSet)

  static async insert(userId: string, keyword: string, groupName: string = ''): Promise<Keyword> {
    try {
      const kw = new Keyword()
      kw.id = generateId()
      kw.userId = userId
      kw.keyword = keyword
      kw.groupName = groupName
      kw.useCount = 0
      kw.createdAt = getTimestamp()

      const bucket: relationalStore.ValuesBucket = {
        'id': kw.id,
        'user_id': kw.userId,
        'keyword': kw.keyword,
        'group_name': kw.groupName.length > 0 ? kw.groupName : null,
        'use_count': kw.useCount,
        'created_at': kw.createdAt
      }
      await KeywordDao.baseDao.getStore().insert(DatabaseSchema.TABLE_KEYWORDS, bucket)
      return kw
    } catch (err) {
      throw new Error(`Failed to insert keyword: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<Keyword[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('use_count')
      return await KeywordDao.baseDao.queryList(predicates, 'KeywordDao.findByUserId')
    } catch (err) {
      throw new Error(`Failed to find keywords by user: ${String(err)}`)
    }
  }

  static async findByGroup(userId: string, groupName: string): Promise<Keyword[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('user_id', userId)
      predicates.equalTo('group_name', groupName)
      predicates.orderByDesc('use_count')
      return await KeywordDao.baseDao.queryList(predicates, 'KeywordDao.findByGroup')
    } catch (err) {
      throw new Error(`Failed to find keywords by group: ${String(err)}`)
    }
  }

  static async incrementUseCount(id: string): Promise<void> {
    try {
      const store = KeywordDao.baseDao.getStore()
      await store.executeSql(
        `UPDATE ${DatabaseSchema.TABLE_KEYWORDS} SET use_count = use_count + 1 WHERE id = ?`,
        [id]
      )
    } catch (err) {
      Logger.error('Failed to increment keyword use count: %{public}s', String(err))
      throw new Error(`Failed to increment keyword use count: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<Keyword | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('id', id)
      return await KeywordDao.baseDao.queryFirst(predicates, 'KeywordDao.findById')
    } catch (err) {
      throw new Error(`Failed to find keyword by id: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('user_id', userId)
      return await KeywordDao.baseDao.count(predicates, 'KeywordDao.countByUserId')
    } catch (err) {
      throw new Error(`Failed to count keywords: ${String(err)}`)
    }
  }

  static async update(keyword: Keyword): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('id', keyword.id)
      const bucket: relationalStore.ValuesBucket = {
        'keyword': keyword.keyword,
        'group_name': keyword.groupName.length > 0 ? keyword.groupName : null,
        'use_count': keyword.useCount
      }
      await KeywordDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update keyword: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('id', id)
      await KeywordDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete keyword: ${String(err)}`)
    }
  }

  static fromResultSet(rs: relationalStore.ResultSet): Keyword {
    try {
      const kw = new Keyword()
      kw.id = rs.getString(rs.getColumnIndex('id'))
      kw.userId = rs.getString(rs.getColumnIndex('user_id'))
      kw.keyword = rs.getString(rs.getColumnIndex('keyword'))
      kw.groupName = rs.isColumnNull(rs.getColumnIndex('group_name')) ? '' : rs.getString(rs.getColumnIndex('group_name'))
      kw.useCount = rs.getLong(rs.getColumnIndex('use_count'))
      kw.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      return kw
    } catch (err) {
      throw new Error(`Failed to map keyword result set: ${String(err)}`)
    }
  }
}
