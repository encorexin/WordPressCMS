// 通用列表数据源，配合 LazyForEach 使用

/** 计算列表缓存数量：Math.ceil(可见项数 × 1.5) */
export function calcCachedCount(visibleCount: number): number {
  return Math.ceil(visibleCount * 1.5)
}

export class BasicDataSource<T> implements IDataSource {
  private dataArray: T[] = []
  private listeners: DataChangeListener[] = []

  constructor(data: T[] = []) {
    this.dataArray = data
  }

  totalCount(): number {
    return this.dataArray.length
  }

  getData(index: number): T {
    return this.dataArray[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  setData(data: T[]): void {
    this.dataArray = data
    this.notifyDataReload()
  }

  private notifyDataReload(): void {
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onDataReloaded()
    }
  }
}
