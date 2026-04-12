// 认证状态管理 — AppStorage 驱动登录状态

import { AppStorageKeys, UserRole } from '../constants/AppStorageKeys'

export class AuthStore {

  // 初始化认证状态（在 EntryAbility.onCreate 中调用）
  static initialize(): void {
    AppStorage.setOrCreate<boolean>(AppStorageKeys.IS_LOGGED_IN, false)
    AppStorage.setOrCreate<string>(AppStorageKeys.CURRENT_USER_ID, '')
    AppStorage.setOrCreate<string>(AppStorageKeys.CURRENT_USER_ROLE, UserRole.User)
  }

  // 是否已登录
  static isLoggedIn(): boolean {
    return AppStorage.get<boolean>(AppStorageKeys.IS_LOGGED_IN) || false
  }

  // 获取当前用户 ID
  static getCurrentUserId(): string {
    return AppStorage.get<string>(AppStorageKeys.CURRENT_USER_ID) || ''
  }

  // 获取当前用户角色
  static getCurrentUserRole(): UserRole {
    const role = AppStorage.get<string>(AppStorageKeys.CURRENT_USER_ROLE) || UserRole.User
    if (role === UserRole.Admin) {
      return UserRole.Admin
    }
    return UserRole.User
  }

  // 是否为管理员
  static isAdmin(): boolean {
    return AuthStore.getCurrentUserRole() === UserRole.Admin
  }

  // 写入登录状态
  static setLoggedIn(userId: string, role: UserRole): void {
    AppStorage.set<boolean>(AppStorageKeys.IS_LOGGED_IN, true)
    AppStorage.set<string>(AppStorageKeys.CURRENT_USER_ID, userId)
    AppStorage.set<string>(AppStorageKeys.CURRENT_USER_ROLE, role)
  }

  // 清除登录状态
  static clearAuth(): void {
    AppStorage.set<boolean>(AppStorageKeys.IS_LOGGED_IN, false)
    AppStorage.set<string>(AppStorageKeys.CURRENT_USER_ID, '')
    AppStorage.set<string>(AppStorageKeys.CURRENT_USER_ROLE, UserRole.User)
  }
}
