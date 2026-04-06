// 本地认证服务 — 注册/登录/会话管理

import { UserDao } from '../db/UserDao'
import { CryptoService } from '../crypto/CryptoService'
import { Logger } from '../../utils/Logger'
import { User } from '../../models/User'

// 认证结果
export class AuthResult {
  success: boolean = false
  user: User | null = null
  error: string = ''
}

export class AuthService {

  // 注册
  static async register(email: string, password: string): Promise<AuthResult> {
    const result = new AuthResult()
    try {
      // 校验输入
      if (email.length === 0 || password.length === 0) {
        result.error = '邮箱和密码不能为空'
        return result
      }
      if (password.length < 6) {
        result.error = '密码至少6位'
        return result
      }

      // 检查邮箱是否已注册
      const existing = await UserDao.findByEmail(email)
      if (existing !== null) {
        result.error = '该邮箱已注册'
        return result
      }

      // 第一个用户自动成为管理员
      const userCount = await UserDao.count()
      const role = userCount === 0 ? 'admin' : 'user'

      // 哈希密码
      const passwordHash = await CryptoService.hashPassword(password)

      // 创建用户
      const user = await UserDao.insert(email, passwordHash, role)

      // 设置运行时加密密码
      CryptoService.setPassword(password)

      // 写入 AppStorage（由调用方负责）
      result.success = true
      result.user = user
      return result
    } catch (err) {
      Logger.error('Register failed: %{public}s', String(err))
      result.error = '注册失败，请重试'
      return result
    }
  }

  // 登录
  static async login(email: string, password: string): Promise<AuthResult> {
    const result = new AuthResult()
    try {
      if (email.length === 0 || password.length === 0) {
        result.error = '邮箱和密码不能为空'
        return result
      }

      const user = await UserDao.findByEmail(email)
      if (user === null) {
        result.error = '邮箱或密码错误'
        return result
      }

      const valid = await CryptoService.verifyPassword(password, user.passwordHash)
      if (!valid) {
        result.error = '邮箱或密码错误'
        return result
      }

      // 设置运行时加密密码
      CryptoService.setPassword(password)

      result.success = true
      result.user = user
      return result
    } catch (err) {
      Logger.error('Login failed: %{public}s', String(err))
      result.error = '登录失败，请重试'
      return result
    }
  }

  // 登出
  static logout(): void {
    CryptoService.clearPassword()
    AppStorage.set<boolean>('isLoggedIn', false)
    AppStorage.set<string>('currentUserId', '')
    AppStorage.set<string>('currentUserRole', '')
  }

  // 将认证状态写入 AppStorage
  static applySession(user: User): void {
    AppStorage.set<boolean>('isLoggedIn', true)
    AppStorage.set<string>('currentUserId', user.id)
    AppStorage.set<string>('currentUserRole', user.role)
  }

  // 验证当前会话是否有效（数据库中用户仍存在）
  static async validateSession(): Promise<boolean> {
    const userId = AppStorage.get<string>('currentUserId') || ''
    if (userId.length === 0) {
      return false
    }
    try {
      const user = await UserDao.findById(userId)
      if (user === null) {
        return false
      }
      // 检查加密服务是否已初始化
      if (!CryptoService.isInitialized()) {
        return false
      }
      return true
    } catch (_err) {
      return false
    }
  }

  // 获取当前登录用户
  static async getCurrentUser(): Promise<User | null> {
    const userId = AppStorage.get<string>('currentUserId') || ''
    if (userId.length === 0) {
      return null
    }
    return await UserDao.findById(userId)
  }
}
