// 模板表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { ArticleTemplate } from '../../models/ArticleTemplate'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'

export class TemplateDao {
  private static getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  static async insert(userId: string, name: string, description: string,
    systemPrompt: string): Promise<ArticleTemplate> {
    try {
      const now = getTimestamp()
      const template = new ArticleTemplate()
      template.id = generateId()
      template.userId = userId
      template.name = name
      template.description = description
      template.systemPrompt = systemPrompt
      template.createdAt = now
      template.updatedAt = now

      const bucket: relationalStore.ValuesBucket = {
        'id': template.id,
        'user_id': template.userId,
        'name': template.name,
        'description': template.description,
        'system_prompt': template.systemPrompt,
        'created_at': template.createdAt,
        'updated_at': template.updatedAt
      }
      await TemplateDao.getStore().insert(DatabaseSchema.TABLE_TEMPLATES, bucket)
      return template
    } catch (err) {
      throw new Error(`Failed to insert template: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<ArticleTemplate[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TEMPLATES)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('created_at')
      resultSet = await TemplateDao.getStore().query(predicates)
      const list: ArticleTemplate[] = []
      while (resultSet.goToNextRow()) {
        list.push(TemplateDao.fromResultSet(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`Failed to find templates by user: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async findById(id: string): Promise<ArticleTemplate | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TEMPLATES)
      predicates.equalTo('id', id)
      resultSet = await TemplateDao.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return TemplateDao.fromResultSet(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`Failed to find template by id: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try { resultSet.close() } catch (_err) {}
      }
    }
  }

  static async update(template: ArticleTemplate): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TEMPLATES)
      predicates.equalTo('id', template.id)
      const bucket: relationalStore.ValuesBucket = {
        'name': template.name,
        'description': template.description,
        'system_prompt': template.systemPrompt,
        'updated_at': getTimestamp()
      }
      await TemplateDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update template: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_TEMPLATES)
      predicates.equalTo('id', id)
      await TemplateDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete template: ${String(err)}`)
    }
  }

  private static fromResultSet(rs: relationalStore.ResultSet): ArticleTemplate {
    try {
      const t = new ArticleTemplate()
      t.id = rs.getString(rs.getColumnIndex('id'))
      t.userId = rs.getString(rs.getColumnIndex('user_id'))
      t.name = rs.getString(rs.getColumnIndex('name'))
      t.description = rs.isColumnNull(rs.getColumnIndex('description')) ? '' : rs.getString(rs.getColumnIndex('description'))
      t.systemPrompt = rs.getString(rs.getColumnIndex('system_prompt'))
      t.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      t.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return t
    } catch (err) {
      throw new Error(`Failed to map template result set: ${String(err)}`)
    }
  }
}
