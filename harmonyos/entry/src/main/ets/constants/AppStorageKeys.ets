export class AppStorageKeys {
  static readonly IS_LOGGED_IN: string = 'isLoggedIn'
  static readonly CURRENT_USER_ID: string = 'currentUserId'
  static readonly CURRENT_USER_ROLE: string = 'currentUserRole'
  static readonly THEME_MODE: string = 'themeMode'
  static readonly SYSTEM_COLOR_MODE: string = 'systemColorMode'
  static readonly CURRENT_BREAKPOINT: string = 'currentBreakpoint'
  static readonly DASHBOARD_REFRESH_SIGNAL: string = 'dashboardRefreshSignal'
  static readonly ARTICLES_NEED_REFRESH: string = 'articlesNeedRefresh'
}

export enum UserRole {
  User = 'user',
  Admin = 'admin',
}

export enum ThemeMode {
  Light = 'light',
  Dark = 'dark',
  System = 'system',
}

export enum ThemeColorMode {
  Light = 0,
  Dark = 1,
  System = -1,
}
