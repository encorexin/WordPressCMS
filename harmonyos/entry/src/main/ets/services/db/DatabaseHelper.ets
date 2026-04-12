// 数据库初始化 + 版本迁移

import relationalStore from '@ohos.data.relationalStore'
import { DatabaseSchema } from '../../constants/DatabaseSchema'
import { getTimestamp } from '../../utils/DateUtil'
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
      await DatabaseHelper.ensureSchemaUpToDate()
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
    } catch (err) {
      Logger.error('Failed to create tables: %{public}s', String(err))
      throw new Error(String(err))
    }
  }

  private static async ensureSchemaUpToDate(): Promise<void> {
    const currentVersion = await DatabaseHelper.getSchemaVersion()
    if (currentVersion > DatabaseSchema.DB_VERSION) {
      throw new Error(`Unsupported schema version: ${currentVersion}`)
    }
    if (currentVersion === DatabaseSchema.DB_VERSION) {
      Logger.info('Database schema already up to date: %{public}s', `${currentVersion}`)
      return
    }

    let nextVersion = currentVersion
    while (nextVersion < DatabaseSchema.DB_VERSION) {
      if (nextVersion === DatabaseSchema.LEGACY_SCHEMA_VERSION) {
        await DatabaseHelper.migrateVersion1To2()
        nextVersion = 2
        await DatabaseHelper.saveSchemaVersion(nextVersion)
        continue
      }
      throw new Error(`Unsupported schema migration path: ${nextVersion} -> ${DatabaseSchema.DB_VERSION}`)
    }
  }

  private static async getSchemaVersion(): Promise<number> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      const store = DatabaseHelper.getStore()
      const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SCHEMA_METADATA)
      predicates.equalTo('meta_key', DatabaseSchema.META_KEY_SCHEMA_VERSION)
      resultSet = await store.query(predicates)
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('meta_value'))
      }
      Logger.info(
        'Schema version metadata missing, fallback to legacy baseline: %{public}s',
        `${DatabaseSchema.LEGACY_SCHEMA_VERSION}`
      )
      return DatabaseSchema.LEGACY_SCHEMA_VERSION
    } catch (err) {
      Logger.error('Failed to query schema version: %{public}s', String(err))
      throw new Error(`Failed to query schema version: ${String(err)}`)
    } finally {
      DatabaseHelper.closeResultSet(resultSet, 'query schema version')
    }
  }

  private static async migrateVersion1To2(): Promise<void> {
    const store = DatabaseHelper.getStore()
    Logger.info('Running schema migration from version 1 to version 2')
    for (let i = 0; i < DatabaseSchema.VERSION_1_TO_2_MIGRATIONS.length; i++) {
      const sql = DatabaseSchema.VERSION_1_TO_2_MIGRATIONS[i]
      try {
        await store.executeSql(sql)
      } catch (migrationErr) {
        if (sql.startsWith('ALTER TABLE ')) {
          Logger.debug('Version 2 migration SQL skipped: %{public}s', String(migrationErr))
          continue
        }
        Logger.error('Failed to execute migration SQL: %{public}s', String(migrationErr))
        throw new Error(`Failed to execute migration SQL: ${String(migrationErr)}`)
      }
    }
  }

  private static async saveSchemaVersion(version: number): Promise<void> {
    const store = DatabaseHelper.getStore()
    const predicates = new relationalStore.RdbPredicates(DatabaseSchema.TABLE_SCHEMA_METADATA)
    predicates.equalTo('meta_key', DatabaseSchema.META_KEY_SCHEMA_VERSION)
    const bucket: relationalStore.ValuesBucket = {
      'meta_value': version,
      'updated_at': getTimestamp()
    }

    try {
      const updatedRows = await store.update(bucket, predicates)
      if (updatedRows === 0) {
        await store.insert(DatabaseSchema.TABLE_SCHEMA_METADATA, {
          'meta_key': DatabaseSchema.META_KEY_SCHEMA_VERSION,
          'meta_value': version,
          'updated_at': getTimestamp()
        })
      }
      Logger.info('Persisted schema version: %{public}s', `${version}`)
    } catch (err) {
      Logger.error('Failed to persist schema version: %{public}s', String(err))
      throw new Error(`Failed to persist schema version: ${String(err)}`)
    }
  }

  private static closeResultSet(resultSet: relationalStore.ResultSet | null, context: string): void {
    if (resultSet === null) {
      return
    }
    try {
      resultSet.close()
    } catch (closeErr) {
      Logger.warn('Failed to close result set during %{public}s: %{public}s', context, String(closeErr))
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
