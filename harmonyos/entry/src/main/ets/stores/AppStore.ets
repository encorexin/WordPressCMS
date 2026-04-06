// 全局应用状态初始化 — 在 EntryAbility.onCreate 统一调用

import { ThemeStore } from './ThemeStore'
import { AuthStore } from './AuthStore'

export class AppStore {

  // 初始化全部全局状态
  static initialize(): void {
    ThemeStore.initialize()
    AuthStore.initialize()
    AppStore.initBreakpoint()
  }

  // 初始化断点状态
  private static initBreakpoint(): void {
    AppStorage.setOrCreate<string>('currentBreakpoint', 'sm')
  }

  // 更新断点（在根组件中通过 GridRow 的 onBreakpointChange 回调调用）
  static updateBreakpoint(breakpoint: string): void {
    AppStorage.set<string>('currentBreakpoint', breakpoint)
  }

  // 获取当前断点
  static getBreakpoint(): string {
    return AppStorage.get<string>('currentBreakpoint') || 'sm'
  }
}
