// 认证状态管理 — AppStorage 驱动登录状态

export class AuthStore {

  // 初始化认证状态（在 EntryAbility.onCreate 中调用）
  static initialize(): void {
    AppStorage.setOrCreate<boolean>('isLoggedIn', false)
    AppStorage.setOrCreate<string>('currentUserId', '')
    AppStorage.setOrCreate<string>('currentUserRole', '')
  }

  // 是否已登录
  static isLoggedIn(): boolean {
    return AppStorage.get<boolean>('isLoggedIn') || false
  }

  // 获取当前用户 ID
  static getCurrentUserId(): string {
    return AppStorage.get<string>('currentUserId') || ''
  }

  // 获取当前用户角色
  static getCurrentUserRole(): string {
    return AppStorage.get<string>('currentUserRole') || ''
  }

  // 是否为管理员
  static isAdmin(): boolean {
    return AuthStore.getCurrentUserRole() === 'admin'
  }

  // 写入登录状态
  static setLoggedIn(userId: string, role: string): void {
    AppStorage.set<boolean>('isLoggedIn', true)
    AppStorage.set<string>('currentUserId', userId)
    AppStorage.set<string>('currentUserRole', role)
  }

  // 清除登录状态
  static clearAuth(): void {
    AppStorage.set<boolean>('isLoggedIn', false)
    AppStorage.set<string>('currentUserId', '')
    AppStorage.set<string>('currentUserRole', '')
  }
}
