// AI 设置表 CRUD

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { AISettingsModel } from '../../models/AISettings'
import { generateId } from '../../utils/IdGenerator'
import { getTimestamp } from '../../utils/DateUtil'
import { Logger } from '../../utils/Logger'
import { CryptoService } from '../crypto/CryptoService'
import { BaseDao } from './BaseDao'

export class AISettingsDao {
  private static readonly baseDao: BaseDao<AISettingsModel> =
    new BaseDao<AISettingsModel>(DatabaseSchema.TABLE_AI_SETTINGS, AISettingsDao.syncFromResultSet)

  static async insert(settings: AISettingsModel): Promise<AISettingsModel> {
    try {
      const now = getTimestamp()
      settings.id = generateId()
      settings.createdAt = now
      settings.updatedAt = now

      const encryptedApiKey = await CryptoService.encryptField(settings.apiKey)
      const encryptedImageApiKey = await CryptoService.encryptField(settings.imageApiKey)

      const bucket: relationalStore.ValuesBucket = {
        'id': settings.id,
        'user_id': settings.userId,
        'name': settings.name,
        'is_default': settings.isDefault ? 1 : 0,
        'api_endpoint': settings.apiEndpoint,
        'api_key': encryptedApiKey,
        'model': settings.model,
        'system_prompt': settings.systemPrompt,
        'image_provider': settings.imageProvider,
        'image_api_key': encryptedImageApiKey,
        'image_endpoint': settings.imageEndpoint,
        'image_model': settings.imageModel,
        'image_enabled': settings.imageEnabled ? 1 : 0,
        'slug_model': settings.slugModel,
        'slug_enabled': settings.slugEnabled ? 1 : 0,
        'tokens_used': settings.tokensUsed,
        'created_at': settings.createdAt,
        'updated_at': settings.updatedAt
      }
      await AISettingsDao.baseDao.getStore().insert(DatabaseSchema.TABLE_AI_SETTINGS, bucket)
      return settings
    } catch (err) {
      throw new Error(`Failed to insert AI settings: ${String(err)}`)
    }
  }

  static async findByUserId(userId: string): Promise<AISettingsModel[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('user_id', userId)
      predicates.orderByDesc('is_default')
      return await AISettingsDao.baseDao.queryListAsync(predicates, 'AISettingsDao.findByUserId', AISettingsDao.fromResultSet)
    } catch (err) {
      throw new Error(`Failed to find AI settings by user: ${String(err)}`)
    }
  }

  static async findDefault(userId: string): Promise<AISettingsModel | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('user_id', userId)
      predicates.equalTo('is_default', 1)
      return await AISettingsDao.baseDao.queryFirstAsync(predicates, 'AISettingsDao.findDefault', AISettingsDao.fromResultSet)
    } catch (err) {
      throw new Error(`Failed to find default AI settings: ${String(err)}`)
    }
  }

  static async findById(id: string): Promise<AISettingsModel | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('id', id)
      return await AISettingsDao.baseDao.queryFirstAsync(predicates, 'AISettingsDao.findById', AISettingsDao.fromResultSet)
    } catch (err) {
      throw new Error(`Failed to find AI settings by id: ${String(err)}`)
    }
  }

  static async countByUserId(userId: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('user_id', userId)
      return await AISettingsDao.baseDao.count(predicates, 'AISettingsDao.countByUserId')
    } catch (err) {
      throw new Error(`Failed to count AI settings by user: ${String(err)}`)
    }
  }

  static async update(settings: AISettingsModel): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('id', settings.id)
      const encryptedApiKey = await CryptoService.encryptField(settings.apiKey)
      const encryptedImageApiKey = await CryptoService.encryptField(settings.imageApiKey)
      const bucket: relationalStore.ValuesBucket = {
        'name': settings.name,
        'is_default': settings.isDefault ? 1 : 0,
        'api_endpoint': settings.apiEndpoint,
        'api_key': encryptedApiKey,
        'model': settings.model,
        'system_prompt': settings.systemPrompt,
        'image_provider': settings.imageProvider,
        'image_api_key': encryptedImageApiKey,
        'image_endpoint': settings.imageEndpoint,
        'image_model': settings.imageModel,
        'image_enabled': settings.imageEnabled ? 1 : 0,
        'slug_model': settings.slugModel,
        'slug_enabled': settings.slugEnabled ? 1 : 0,
        'tokens_used': settings.tokensUsed,
        'updated_at': getTimestamp()
      }
      await AISettingsDao.baseDao.getStore().update(bucket, predicates)
    } catch (err) {
      throw new Error(`Failed to update AI settings: ${String(err)}`)
    }
  }

  static async addTokensUsed(settingsId: string, delta: number): Promise<void> {
    if (delta <= 0) return
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('id', settingsId)
      resultSet = await AISettingsDao.baseDao.getStore().query(predicates, ['tokens_used'])
      let current = 0
      if (resultSet.goToFirstRow()) {
        try {
          const idx = resultSet.getColumnIndex('tokens_used')
          current = resultSet.isColumnNull(idx) ? 0 : resultSet.getLong(idx)
        } catch (tokensErr) {
          Logger.debug('AISettingsDao.addTokensUsed tokens_used fallback: %{public}s', String(tokensErr))
          current = 0
        }
      }
      const next = current + delta
      const updatePred = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      updatePred.equalTo('id', settingsId)
      const bucket: relationalStore.ValuesBucket = { 'tokens_used': next, 'updated_at': getTimestamp() }
      await AISettingsDao.baseDao.getStore().update(bucket, updatePred)
    } catch (err) {
      throw new Error(`Failed to add tokens used: ${String(err)}`)
    } finally {
      if (resultSet !== null) {
        try {
          resultSet.close()
        } catch (closeErr) {
          Logger.warn('AISettingsDao.addTokensUsed close resultSet failed: %{public}s', String(closeErr))
        }
      }
    }
  }

  static async setDefault(userId: string, settingsId: string): Promise<void> {
    const store = AISettingsDao.baseDao.getStore()
    try {
      // 先查找当前默认设置
      const currentDefaultPred = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      currentDefaultPred.equalTo('user_id', userId).and().equalTo('is_default', 1)
      const currentResult = await store.query(currentDefaultPred, ['id'])
      const previousDefaultIds: string[] = []
      while (currentResult.goToNextRow()) {
        previousDefaultIds.push(currentResult.getString(currentResult.getColumnIndex('id')))
      }
      currentResult.close()

      // 清除所有默认
      const clearPredicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      clearPredicates.equalTo('user_id', userId)
      const clearBucket: relationalStore.ValuesBucket = { 'is_default': 0 }
      await store.update(clearBucket, clearPredicates)

      // 设置新默认
      try {
        const setPredicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
        setPredicates.equalTo('id', settingsId)
        const setBucket: relationalStore.ValuesBucket = { 'is_default': 1 }
        await store.update(setBucket, setPredicates)
      } catch (setErr) {
        // 回滚：恢复之前的默认设置
        for (let i = 0; i < previousDefaultIds.length; i++) {
          const restorePred = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
          restorePred.equalTo('id', previousDefaultIds[i])
          const restoreBucket: relationalStore.ValuesBucket = { 'is_default': 1 }
          await store.update(restoreBucket, restorePred)
        }
        throw new Error(`Failed to set new default: ${String(setErr)}`)
      }
    } catch (err) {
      throw new Error(`Failed to set default AI settings: ${String(err)}`)
    }
  }

  static async deleteById(id: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_AI_SETTINGS)
      predicates.equalTo('id', id)
      await AISettingsDao.baseDao.getStore().delete(predicates)
    } catch (err) {
      throw new Error(`Failed to delete AI settings: ${String(err)}`)
    }
  }

  /** 同步映射 — 供 BaseDao 构造函数使用（不支持解密，仅 count 等 SQL 聚合场景） */
  private static syncFromResultSet(_rs: relationalStore.ResultSet): AISettingsModel {
    // AISettingsDao 的完整映射需要异步解密，此处仅作 BaseDao 占位
    const s = new AISettingsModel()
    return s
  }

  /** 异步映射 — 支持加密字段解密 */
  static async fromResultSet(rs: relationalStore.ResultSet): Promise<AISettingsModel> {
    try {
      const s = new AISettingsModel()
      s.id = rs.getString(rs.getColumnIndex('id'))
      s.userId = rs.getString(rs.getColumnIndex('user_id'))
      s.name = rs.getString(rs.getColumnIndex('name'))
      s.isDefault = rs.getLong(rs.getColumnIndex('is_default')) === 1
      s.apiEndpoint = rs.isColumnNull(rs.getColumnIndex('api_endpoint')) ? '' : rs.getString(rs.getColumnIndex('api_endpoint'))
      const storedApiKey = rs.isColumnNull(rs.getColumnIndex('api_key')) ? '' : rs.getString(rs.getColumnIndex('api_key'))
      s.apiKey = await CryptoService.decryptField(storedApiKey)
      s.model = rs.isColumnNull(rs.getColumnIndex('model')) ? '' : rs.getString(rs.getColumnIndex('model'))
      s.systemPrompt = rs.isColumnNull(rs.getColumnIndex('system_prompt')) ? '' : rs.getString(rs.getColumnIndex('system_prompt'))
      s.imageProvider = rs.isColumnNull(rs.getColumnIndex('image_provider')) ? '' : rs.getString(rs.getColumnIndex('image_provider'))
      const storedImageApiKey = rs.isColumnNull(rs.getColumnIndex('image_api_key')) ? '' : rs.getString(rs.getColumnIndex('image_api_key'))
      s.imageApiKey = await CryptoService.decryptField(storedImageApiKey)
      s.imageEndpoint = rs.isColumnNull(rs.getColumnIndex('image_endpoint')) ? '' : rs.getString(rs.getColumnIndex('image_endpoint'))
      s.imageModel = rs.isColumnNull(rs.getColumnIndex('image_model')) ? '' : rs.getString(rs.getColumnIndex('image_model'))
      s.imageEnabled = rs.getLong(rs.getColumnIndex('image_enabled')) === 1
      s.slugModel = rs.isColumnNull(rs.getColumnIndex('slug_model')) ? '' : rs.getString(rs.getColumnIndex('slug_model'))
      s.slugEnabled = rs.getLong(rs.getColumnIndex('slug_enabled')) === 1
      try {
        const tkIndex = rs.getColumnIndex('tokens_used')
        s.tokensUsed = rs.isColumnNull(tkIndex) ? 0 : rs.getLong(tkIndex)
      } catch (tokensErr) {
        Logger.debug('AISettingsDao.fromResultSet tokens_used fallback: %{public}s', String(tokensErr))
        s.tokensUsed = 0
      }
      s.createdAt = rs.getString(rs.getColumnIndex('created_at'))
      s.updatedAt = rs.getString(rs.getColumnIndex('updated_at'))
      return s
    } catch (err) {
      throw new Error(`Failed to map AI settings result set: ${String(err)}`)
    }
  }
}
