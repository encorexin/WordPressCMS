// 主题表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Topic } from '../../models/Topic'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { BaseDao } from './BaseDao'

export class TopicDao {
  private static readonly baseDao: BaseDao<Topic> = new BaseDao<Topic>(DatabaseSchema.TABLE_TOPICS, TopicDao.fromResultSet)

  static async insert(userId: string, title: string, description: string,
    keywords: string, category: string): Promise<Topic> {
    try {
      const topic = new Topic()
      topic.id = generateId()
      topic.userId = userId
      topic.title = title
      topic.description = description
      topic.keywords = keywords
      topic.category = category
      topic.used = false
      topic.createdAt = getTimestamp()

      const bucket: relationalStore.ValuesBucket = {
        'id': topic.id,
        'user_id': topic.userId,
        'title': topic.title,
        'description': topic.description,
        'keywords': topic.keywords,
        'category': topic.category,
        'used': 0,
        'created_at': topic.createdAt
      }
      await TopicDao.baseDao.getStore().insert(DatabaseSchema.TABLE_TOPICS, bucket)
      return topic
    } catch (err) {
      throw new Error(`Failed to insert topic: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string, usedFilter: number = -1): Promise<Topic[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('user_id', userId)
      if (usedFilter >= 0) {
        predicates.equalTo('used', usedFilter)
      }
      predicates.orderByDesc('created_at')
      return await TopicDao.baseDao.queryList(predicates, 'TopicDao.findByUserId')
    } catch (err) {
      throw new Error(`Failed to find topics by user: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<Topic | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('id', id)
      return await TopicDao.baseDao.queryFirst(predicates, 'TopicDao.findById')
    } catch (err) {
      throw new Error(`Failed to find topic by id: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('user_id', userId)
      return await TopicDao.baseDao.count(predicates, 'TopicDao.countByUserId')
    } catch (err) {
      throw new Error(`Failed to count topics: ${String(err)}`)
    }
  }

  static async markUsed(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('id', id)
      const bucket: relationalStore.ValuesBucket = { 'used': 1 }
      await TopicDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to mark topic used: ${String(err)}`)
    }
  }

  static async update(topic: Topic): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('id', topic.id)
      const bucket: relationalStore.ValuesBucket = {
        'title': topic.title,
        'description': topic.description,
        'keywords': topic.keywords,
        'category': topic.category,
        'used': topic.used ? 1 : 0
      }
      await TopicDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update topic: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TOPICS)
      predicates.equalTo('id', id)
      await TopicDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete topic: ${String(err)}`)
    }
  }

  static fromResultSet(rs: relationalStore.ResultSet): Topic {
    try {
      const t = new Topic()
      t.id = rs.getString(rs.getColumnIndex('id'))
      t.userId = rs.getString(rs.getColumnIndex('user_id'))
      t.title = rs.getString(rs.getColumnIndex('title'))
      t.description = rs.isColumnNull(rs.getColumnIndex('description')) ? '' : rs.getString(rs.getColumnIndex('description'))
      t.keywords = rs.isColumnNull(rs.getColumnIndex('keywords')) ? '' : rs.getString(rs.getColumnIndex('keywords'))
      t.category = rs.isColumnNull(rs.getColumnIndex('category')) ? '' : rs.getString(rs.getColumnIndex('category'))
      t.used = rs.getLong(rs.getColumnIndex('used')) === 1
      t.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      return t
    } catch (err) {
      throw new Error(`Failed to map topic result set: ${String(err)}`)
    }
  }
}
