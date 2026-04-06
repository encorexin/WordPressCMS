// 数据库初始化 + 版本迁移

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { Logger } from '../../utils/Logger'

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DatabaseSchema.DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
}

let rdbStore: relationalStore.RdbStore | null = null
let initPromise: Promise<void> | null = null

export class DatabaseHelper {
  static async initialize(context: Context): Promise<void> {
    if (rdbStore !== null) {
      return
    }
    if (initPromise !== null) {
      return initPromise
    }
    initPromise = DatabaseHelper.doInitialize(context)
    try {
      await initPromise
    } finally {
      initPromise = null
    }
  }

  private static async doInitialize(context: Context): Promise<void> {
    try {
      rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await DatabaseHelper.createTables()
      Logger.info('Database initialized successfully')
    } catch (err) {
      Logger.error('Failed to initialize database: %{public}s', String(err))
      throw new Error(String(err))
    }
  }

  private static async createTables(): Promise<void> {
    if (rdbStore === null) {
      return
    }
    try {
      for (let i = 0; i < DatabaseSchema.ALL_CREATE_TABLES.length; i++) {
        await rdbStore.executeSql(DatabaseSchema.ALL_CREATE_TABLES[i])
      }
      for (let i = 0; i < DatabaseSchema.ALL_SAFE_ALTERS.length; i++) {
        try {
          await rdbStore.executeSql(DatabaseSchema.ALL_SAFE_ALTERS[i])
        } catch (alterErr) {
          Logger.debug('ALTER skipped (likely already exists): %{public}s', String(alterErr))
        }
      }
    } catch (err) {
      Logger.error('Failed to create tables: %{public}s', String(err))
      throw new Error(String(err))
    }
  }

  static getStore(): relationalStore.RdbStore {
    if (rdbStore === null) {
      throw new Error('Database not initialized. Call DatabaseHelper.initialize() first.')
    }
    return rdbStore
  }

  static async close(): Promise<void> {
    if (rdbStore !== null) {
      try {
        await rdbStore.close()
      } catch (err) {
        Logger.error('Failed to close database: %{public}s', String(err))
      }
      rdbStore = null
      Logger.info('Database closed')
    }
  }
}
