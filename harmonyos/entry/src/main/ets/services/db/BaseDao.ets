import relationalStore from '@ohos.data.relationalStore'
import { DatabaseHelper } from './DatabaseHelper'
import { Logger } from '../../utils/Logger'

export class BaseDao<T> {
  private readonly tableName: string
  private readonly mapper: (rs: relationalStore.ResultSet) => T

  constructor(tableName: string, mapper: (rs: relationalStore.ResultSet) => T) {
    this.tableName = tableName
    this.mapper = mapper
  }

  getStore(): relationalStore.RdbStore {
    return DatabaseHelper.getStore()
  }

  async queryList(predicates: relationalStore.RdbPredicates, context: string): Promise<T[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.getStore().query(predicates)
      const list: T[] = []
      while (resultSet.goToNextRow()) {
        list.push(this.mapper(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`${context}: ${String(err)}`)
    } finally {
      BaseDao.closeResultSet(resultSet, this.tableName)
    }
  }

  async queryFirst(predicates: relationalStore.RdbPredicates, context: string): Promise<T | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return this.mapper(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`${context}: ${String(err)}`)
    } finally {
      BaseDao.closeResultSet(resultSet, this.tableName)
    }
  }

  async count(predicates: relationalStore.RdbPredicates, context: string): Promise<number> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.getStore().query(predicates, ['COUNT(*) AS total_count'])
      if (resultSet.goToFirstRow()) {
        return resultSet.getLong(resultSet.getColumnIndex('total_count'))
      }
      return 0
    } catch (err) {
      throw new Error(`${context}: ${String(err)}`)
    } finally {
      BaseDao.closeResultSet(resultSet, this.tableName)
    }
  }

  /** 异步 mapper 版本 — 适用于需要解密等异步操作的 fromResultSet */
  async queryListAsync(
    predicates: relationalStore.RdbPredicates,
    context: string,
    asyncMapper: (rs: relationalStore.ResultSet) => Promise<T>
  ): Promise<T[]> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.getStore().query(predicates)
      const list: T[] = []
      while (resultSet.goToNextRow()) {
        list.push(await asyncMapper(resultSet))
      }
      return list
    } catch (err) {
      throw new Error(`${context}: ${String(err)}`)
    } finally {
      BaseDao.closeResultSet(resultSet, this.tableName)
    }
  }

  /** 异步 mapper 版本 — 适用于需要解密等异步操作的 fromResultSet */
  async queryFirstAsync(
    predicates: relationalStore.RdbPredicates,
    context: string,
    asyncMapper: (rs: relationalStore.ResultSet) => Promise<T>
  ): Promise<T | null> {
    let resultSet: relationalStore.ResultSet | null = null
    try {
      resultSet = await this.getStore().query(predicates)
      if (resultSet.goToFirstRow()) {
        return await asyncMapper(resultSet)
      }
      return null
    } catch (err) {
      throw new Error(`${context}: ${String(err)}`)
    } finally {
      BaseDao.closeResultSet(resultSet, this.tableName)
    }
  }

  /** 统一关闭 ResultSet，消除各 DAO 重复的 finally 块 */
  private static closeResultSet(resultSet: relationalStore.ResultSet | null, tableName: string): void {
    if (resultSet === null) {
      return
    }
    try {
      resultSet.close()
    } catch (closeErr) {
      Logger.warn('%{public}s close resultSet failed: %{public}s', tableName, String(closeErr))
    }
  }
}
