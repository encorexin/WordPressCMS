// 加密服务 — AES-GCM 字段级加密 + PBKDF2 密码哈希

import cryptoFramework from '@ohos.security.cryptoFramework'
import util from '@ohos.util'
import { Logger } from '../../utils/Logger'

// 加密常量
const PBKDF2_ITERATIONS: number = 100000
const SALT_LENGTH: number = 16
const IV_LENGTH: number = 12
const KEY_LENGTH: number = 256
const FIELD_ENCRYPTION_PREFIX: string = 'enc:v1:'

// 加密数据格式（JSON 序列化存入数据库字段）
export class EncryptedData {
  salt: string = ''
  iv: string = ''
  data: string = ''
  version: number = 1
}

// 内部持有的派生密钥密码，运行时缓存
let cachedPassword: string = ''

export class CryptoService {

  // ===== 密码哈希（PBKDF2 + SHA-256） =====

  // 对用户密码做 PBKDF2 哈希，返回 "salt:hash" 格式字符串
  static async hashPassword(password: string): Promise<string> {
    const salt = CryptoService.randomBytes(SALT_LENGTH)
    const hash = await CryptoService.pbkdf2(password, salt)
    const saltB64 = CryptoService.uint8ArrayToBase64(salt)
    const hashB64 = CryptoService.uint8ArrayToBase64(hash)
    return `${saltB64}:${hashB64}`
  }

  // 验证密码，比对 "salt:hash" 格式
  static async verifyPassword(password: string, storedHash: string): Promise<boolean> {
    try {
      const parts = storedHash.split(':')
      if (parts.length !== 2) {
        return false
      }
      const salt = CryptoService.base64ToUint8Array(parts[0])
      const expectedHash = CryptoService.base64ToUint8Array(parts[1])
      const actualHash = await CryptoService.pbkdf2(password, salt)
      // 恒定时间比较
      if (actualHash.byteLength !== expectedHash.byteLength) {
        return false
      }
      let diff = 0
      for (let i = 0; i < actualHash.byteLength; i++) {
        diff |= actualHash[i] ^ expectedHash[i]
      }
      return diff === 0
    } catch (err) {
      Logger.error('Password verification failed: %{public}s', String(err))
      return false
    }
  }

  // ===== AES-GCM 字段加密 =====

  // 设置运行时密码（登录时调用）
  static setPassword(password: string): void {
    cachedPassword = password
  }

  // 清除运行时密码（登出时调用）
  static clearPassword(): void {
    cachedPassword = ''
  }

  // 检查加密服务是否已初始化
  static isInitialized(): boolean {
    return cachedPassword.length > 0
  }

  // 加密字符串字段
  static async encrypt(plainText: string, password?: string): Promise<string> {
    const pwd = password || cachedPassword
    if (pwd.length === 0) {
      throw new Error('Encryption password not set')
    }

    try {
      const salt = CryptoService.randomBytes(SALT_LENGTH)
      const iv = CryptoService.randomBytes(IV_LENGTH)
      const keyData = await CryptoService.pbkdf2(pwd, salt)

      const symKeyBlob: cryptoFramework.DataBlob = { data: keyData }
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
      const symKey = await symKeyGenerator.convertKey(symKeyBlob)

      const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7')
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: iv },
        aad: { data: new Uint8Array(0) },
        authTag: { data: new Uint8Array(16) },
        algName: 'GcmParamsSpec'
      }
      await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, gcmParams)

      const encoder = new util.TextEncoder()
      const plainData: cryptoFramework.DataBlob = { data: encoder.encodeInto(plainText) }
      const updateResult = await cipher.doFinal(plainData)
      const cipherBytes = updateResult.data

      const result = new EncryptedData()
      result.salt = CryptoService.uint8ArrayToBase64(salt)
      result.iv = CryptoService.uint8ArrayToBase64(iv)
      result.data = CryptoService.uint8ArrayToBase64(cipherBytes)
      result.version = 1

      return JSON.stringify(result)
    } catch (err) {
      Logger.error('Encryption failed: %{public}s', String(err))
      throw new Error('Encryption failed')
    }
  }

  // 解密字段
  static async decrypt(encryptedJson: string, password?: string): Promise<string> {
    const pwd = password || cachedPassword
    if (pwd.length === 0) {
      throw new Error('Decryption password not set')
    }

    try {
      const encrypted: EncryptedData = JSON.parse(encryptedJson) as EncryptedData
      const salt = CryptoService.base64ToUint8Array(encrypted.salt)
      const iv = CryptoService.base64ToUint8Array(encrypted.iv)
      const cipherBytes = CryptoService.base64ToUint8Array(encrypted.data)
      const keyData = await CryptoService.pbkdf2(pwd, salt)

      // 构建 AES-GCM 密钥
      const symKeyBlob: cryptoFramework.DataBlob = { data: keyData }
      const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256')
      const symKey = await symKeyGenerator.convertKey(symKeyBlob)

      // cipherBytes 的最后 16 字节为 authTag
      const authTagLen = 16
      const actualCipher = cipherBytes.slice(0, cipherBytes.byteLength - authTagLen)
      const authTag = cipherBytes.slice(cipherBytes.byteLength - authTagLen)

      const decipher = cryptoFramework.createCipher('AES256|GCM|PKCS7')
      const gcmParams: cryptoFramework.GcmParamsSpec = {
        iv: { data: iv },
        aad: { data: new Uint8Array(0) },
        authTag: { data: authTag },
        algName: 'GcmParamsSpec'
      }
      await decipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, gcmParams)

      const cipherData: cryptoFramework.DataBlob = { data: actualCipher }
      const decryptResult = await decipher.doFinal(cipherData)

      const decoder = new util.TextDecoder('utf-8')
      return decoder.decodeToString(decryptResult.data)
    } catch (err) {
      Logger.error('Decryption failed: %{public}s', String(err))
      throw new Error('Decryption failed')
    }
  }

  // 判断字符串是否为加密数据
  static isEncrypted(value: string): boolean {
    return CryptoService.parseEncryptedData(value) !== null
  }

  // 判断字段值是否已经是密文
  static isFieldEncrypted(value: string): boolean {
    if (value.length === 0) {
      return false
    }
    if (value.startsWith(FIELD_ENCRYPTION_PREFIX)) {
      return true
    }
    return CryptoService.isEncrypted(value)
  }

  // 字段级加密：新写入统一追加前缀，历史密文保持兼容
  static async encryptField(value: string, password?: string): Promise<string> {
    if (value.length === 0) {
      return ''
    }
    if (value.startsWith(FIELD_ENCRYPTION_PREFIX)) {
      return value
    }
    if (CryptoService.isEncrypted(value)) {
      try {
        const plainText = await CryptoService.decrypt(value, password)
        const encrypted = await CryptoService.encrypt(plainText, password)
        return `${FIELD_ENCRYPTION_PREFIX}${encrypted}`
      } catch (err) {
        Logger.warn('Legacy encrypted field rewrite skipped: %{public}s', String(err))
        return value
      }
    }
    const encrypted = await CryptoService.encrypt(value, password)
    return `${FIELD_ENCRYPTION_PREFIX}${encrypted}`
  }

  // 字段级解密：兼容新前缀密文、旧 JSON 密文和历史明文
  static async decryptField(value: string, password?: string): Promise<string> {
    if (value.length === 0) {
      return ''
    }
    if (value.startsWith(FIELD_ENCRYPTION_PREFIX)) {
      const payload = value.substring(FIELD_ENCRYPTION_PREFIX.length)
      return await CryptoService.decryptFieldPayload(value, payload, password)
    }
    if (CryptoService.isEncrypted(value)) {
      return await CryptoService.decryptFieldPayload(value, value, password)
    }
    return value
  }

  // ===== 内部工具 =====

  private static parseEncryptedData(value: string): EncryptedData | null {
    try {
      const parsed = JSON.parse(value) as EncryptedData
      if (parsed.salt.length === 0 || parsed.iv.length === 0 || parsed.data.length === 0) {
        return null
      }
      return parsed
    } catch (_err) {
      return null
    }
  }

  private static async decryptFieldPayload(originalValue: string, payload: string, password?: string): Promise<string> {
    try {
      return await CryptoService.decrypt(payload, password)
    } catch (err) {
      Logger.warn('Field decryption fallback to stored value: %{public}s', String(err))
      return originalValue
    }
  }

  private static async pbkdf2(password: string, salt: Uint8Array): Promise<Uint8Array> {
    try {
      const encoder = new util.TextEncoder()
      const passwordData = encoder.encodeInto(password)

      const kdfSpec: cryptoFramework.PBKDF2Spec = {
        algName: 'PBKDF2',
        password: passwordData,
        salt: salt,
        iterations: PBKDF2_ITERATIONS,
        keySize: KEY_LENGTH / 8
      }

      const kdf = cryptoFramework.createKdf('PBKDF2|SHA256')
      const derivedKey = await kdf.generateSecret(kdfSpec)
      return derivedKey.data
    } catch (err) {
      Logger.error('PBKDF2 failed: %{public}s', String(err))
      throw new Error('PBKDF2 failed')
    }
  }

  private static randomBytes(length: number): Uint8Array {
    try {
      const random = cryptoFramework.createRandom()
      const blob = random.generateRandomSync(length)
      return blob.data
    } catch (err) {
      Logger.error('Random byte generation failed: %{public}s', String(err))
      throw new Error('Random byte generation failed')
    }
  }

  private static uint8ArrayToBase64(data: Uint8Array): string {
    try {
      const helper = new util.Base64Helper()
      return helper.encodeToStringSync(data)
    } catch (err) {
      Logger.error('Base64 encoding failed: %{public}s', String(err))
      throw new Error('Base64 encoding failed')
    }
  }

  private static base64ToUint8Array(base64: string): Uint8Array {
    try {
      const helper = new util.Base64Helper()
      return helper.decodeSync(base64)
    } catch (err) {
      Logger.error('Base64 decoding failed: %{public}s', String(err))
      throw new Error('Base64 decoding failed')
    }
  }
}
