// 主题状态管理 — light/dark/system 模式切换

import { ConfigurationConstant } from '@kit.AbilityKit'
import { AppStorageKeys, ThemeColorMode, ThemeMode } from '../constants/AppStorageKeys'

export class ThemeStore {

  // 初始化主题（在 EntryAbility.onCreate 中调用）
  static initialize(): void {
    if (!AppStorage.has(AppStorageKeys.THEME_MODE)) {
      AppStorage.setOrCreate<string>(AppStorageKeys.THEME_MODE, ThemeMode.System)
    }
    if (!AppStorage.has(AppStorageKeys.SYSTEM_COLOR_MODE)) {
      AppStorage.setOrCreate<number>(AppStorageKeys.SYSTEM_COLOR_MODE, ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
    }
  }

  // 切换主题
  static setTheme(mode: ThemeMode): void {
    AppStorage.set<string>(AppStorageKeys.THEME_MODE, mode)
  }

  // 获取当前主题模式
  static getTheme(): ThemeMode {
    const mode = AppStorage.get<string>(AppStorageKeys.THEME_MODE) || ThemeMode.System
    if (mode === ThemeMode.Light || mode === ThemeMode.Dark || mode === ThemeMode.System) {
      return mode
    }
    return ThemeMode.System
  }

  // 将 themeMode 转为 ArkUI WithTheme 所需的 colorMode 值
  // 0 = LIGHT, 1 = DARK, -1 = 跟随系统（未设置）
  static getColorMode(): number {
    const mode = ThemeStore.getTheme()
    if (mode === ThemeMode.Light) {
      return ThemeColorMode.Light
    } else if (mode === ThemeMode.Dark) {
      return ThemeColorMode.Dark
    }
    return ThemeColorMode.System
  }

  // 响应系统配置变化（在 EntryAbility.onConfigurationUpdate 中调用）
  static onSystemConfigUpdate(config: ConfigurationConstant.ColorMode): void {
    const mode = ThemeStore.getTheme()
    AppStorage.setOrCreate<number>(AppStorageKeys.SYSTEM_COLOR_MODE, Number(config))
    if (mode === ThemeMode.System) {
      // 系统模式时通知 UI 刷新（WithTheme 自动处理）
      // 此处可扩展通知逻辑
    }
  }
}
