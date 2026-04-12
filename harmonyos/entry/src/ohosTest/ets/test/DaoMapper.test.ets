import relationalStore from '@ohos.data.relationalStore'
import { describe, expect, it } from '@ohos/hypium'
import { KeywordDao } from '../../../main/ets/services/db/KeywordDao'
import { TopicDao } from '../../../main/ets/services/db/TopicDao'

class FakeResultSet {
  private readonly columnIndexMap: Map<string, number>
  private readonly values: Map<number, string | number | null>

  constructor(columns: string[], valuesByColumn: Map<string, string | number | null>) {
    this.columnIndexMap = new Map<string, number>()
    this.values = new Map<number, string | number | null>()
    for (let i = 0; i < columns.length; i++) {
      const columnName = columns[i]
      this.columnIndexMap.set(columnName, i)
      const value = valuesByColumn.get(columnName)
      this.values.set(i, value === undefined ? null : value)
    }
  }

  getColumnIndex(columnName: string): number {
    const index = this.columnIndexMap.get(columnName)
    return index !== undefined ? index : -1
  }

  isColumnNull(columnIndex: number): boolean {
    return this.values.get(columnIndex) === null
  }

  getString(columnIndex: number): string {
    const value = this.values.get(columnIndex)
    return value === null || value === undefined ? '' : String(value)
  }

  getLong(columnIndex: number): number {
    const value = this.values.get(columnIndex)
    if (value === null || value === undefined) return 0
    if (typeof value === 'number') return value
    const parsed = Number(value)
    return Number.isNaN(parsed) ? 0 : parsed
  }
}

export default function daoMapperTest(): void {
  describe('DaoMapperTest', () => {
    it('KeywordDao.fromResultSet maps nullable fields', 0, () => {
      const columns = ['id', 'user_id', 'keyword', 'group_name', 'use_count', 'created_at']
      const valuesByColumn = new Map<string, string | number | null>()
      valuesByColumn.set('id', 'k1')
      valuesByColumn.set('user_id', 'u1')
      valuesByColumn.set('keyword', 'wordpress')
      valuesByColumn.set('group_name', null)
      valuesByColumn.set('use_count', 3)
      valuesByColumn.set('created_at', '2020-01-01T00:00:00.000Z')
      const rs = new FakeResultSet(columns, valuesByColumn) as unknown as relationalStore.ResultSet

      const kw = KeywordDao.fromResultSet(rs)
      expect(kw.id).assertEqual('k1')
      expect(kw.userId).assertEqual('u1')
      expect(kw.keyword).assertEqual('wordpress')
      expect(kw.groupName).assertEqual('')
      expect(kw.useCount).assertEqual(3)
    })

    it('TopicDao.fromResultSet maps used flag', 0, () => {
      const columns = ['id', 'user_id', 'title', 'description', 'keywords', 'category', 'used', 'created_at']
      const valuesByColumn = new Map<string, string | number | null>()
      valuesByColumn.set('id', 't1')
      valuesByColumn.set('user_id', 'u1')
      valuesByColumn.set('title', 'topic')
      valuesByColumn.set('description', null)
      valuesByColumn.set('keywords', 'a,b')
      valuesByColumn.set('category', null)
      valuesByColumn.set('used', 1)
      valuesByColumn.set('created_at', '2020-01-01T00:00:00.000Z')
      const rs = new FakeResultSet(columns, valuesByColumn) as unknown as relationalStore.ResultSet

      const topic = TopicDao.fromResultSet(rs)
      expect(topic.id).assertEqual('t1')
      expect(topic.used).assertEqual(true)
      expect(topic.description).assertEqual('')
      expect(topic.category).assertEqual('')
    })
  })
}

