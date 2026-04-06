// 关键词表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Keyword } from '../../models/Keyword'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { Logger } from '../../utils/Logger'

export class KeywordDao {
  private static getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

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
      await KeywordDao.getStore().insert(DatabaseSchema.TABLE_KEYWORDS, bucket)
      return kw
    } catch (err) {
      throw new Error(`Failed to insert keyword: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<Keyword[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('use_count')
      resultSet = await KeywordDao.getStore().query(predicates)
      const list: Keyword[] = []
      while (resultSet.goToNextRow()) {
        list.push(KeywordDao.fromResultSet(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`Failed to find keywords by user: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async findByGroup(userId: string, groupName: string): Promise<Keyword[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('user_id', userId)
      predicates.equalTo('group_name', groupName)
      predicates.orderByDesc('use_count')
      resultSet = await KeywordDao.getStore().query(predicates)
      const list: Keyword[] = []
      while (resultSet.goToNextRow()) {
        list.push(KeywordDao.fromResultSet(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`Failed to find keywords by group: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async incrementUseCount(id: string): Promise<void> {
    try {
      const store = KeywordDao.getStore()
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
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('id', id)
      resultSet = await KeywordDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return KeywordDao.fromResultSet(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`Failed to find keyword by id: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
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
      await KeywordDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update keyword: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_KEYWORDS)
      predicates.equalTo('id', id)
      await KeywordDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete keyword: ${String(err)}`)
    }
  }

  private static fromResultSet(rs: relationalStore.ResultSet): Keyword {
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
