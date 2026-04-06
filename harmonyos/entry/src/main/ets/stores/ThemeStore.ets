// 主题状态管理 — light/dark/system 模式切换

import { ConfigurationConstant } from '@kit.AbilityKit'

export class ThemeStore {

  // 初始化主题（在 EntryAbility.onCreate 中调用）
  static initialize(): void {
    if (!AppStorage.has('themeMode')) {
      AppStorage.setOrCreate<string>('themeMode', 'system')
    }
  }

  // 切换主题
  static setTheme(mode: string): void {
    AppStorage.set<string>('themeMode', mode)
  }

  // 获取当前主题模式
  static getTheme(): string {
    return AppStorage.get<string>('themeMode') || 'system'
  }

  // 将 themeMode 转为 ArkUI WithTheme 所需的 colorMode 值
  // 0 = LIGHT, 1 = DARK, -1 = 跟随系统（未设置）
  static getColorMode(): number {
    const mode = ThemeStore.getTheme()
    if (mode === 'light') {
      return 0 // ThemeColorMode.LIGHT
    } else if (mode === 'dark') {
      return 1 // ThemeColorMode.DARK
    }
    return -1 // ThemeColorMode.SYSTEM
  }

  // 响应系统配置变化（在 EntryAbility.onConfigurationUpdate 中调用）
  static onSystemConfigUpdate(config: ConfigurationConstant.ColorMode): void {
    const mode = ThemeStore.getTheme()
    if (mode === 'system') {
      // 系统模式时通知 UI 刷新（WithTheme 自动处理）
      // 此处可扩展通知逻辑
    }
  }
}
