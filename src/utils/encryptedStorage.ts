/**
 * 加密存储服务
 * 管理用户数据的加密存储和访问
 */

import { encryptData, decryptData, isEncryptedData, type EncryptedData } from './crypto';
import { storageLogger } from './logger';

// 存储键名
const STORAGE_KEYS = {
    USER_DATA_PREFIX: 'encrypted_data_',
    ENCRYPTION_ENABLED: 'encryption_enabled',
    DATA_VERSION: 'data_version',
    SESSION_KEY: 'session_key_', // 用于存储加密的会话密钥
} as const;

// 当前数据版本
const CURRENT_DATA_VERSION = 1;

// AES-GCM 加密常量
const AES_KEY_LENGTH = 256;
const AES_IV_LENGTH = 12;

// 内存中缓存的解密密钥
let cachedPassword: string | null = null;
let cachedUserId: string | null = null;

/**
 * ArrayBuffer 转 Base64
 */
function arrayBufferToBase64(buffer: ArrayBuffer | Uint8Array): string {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
}

/**
 * Base64 转 ArrayBuffer
 */
function base64ToArrayBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
}

/**
 * 生成 AES-GCM 会话密钥
 */
async function generateSessionKey(): Promise<CryptoKey> {
    return await crypto.subtle.generateKey(
        { name: 'AES-GCM', length: AES_KEY_LENGTH },
        true,
        ['encrypt', 'decrypt']
    );
}

/**
 * 导出 CryptoKey 为 Base64 字符串
 */
async function exportSessionKey(key: CryptoKey): Promise<string> {
    const exported = await crypto.subtle.exportKey('raw', key);
    return arrayBufferToBase64(exported);
}

/**
 * 从 Base64 字符串导入 CryptoKey
 */
async function importSessionKey(keyData: string): Promise<CryptoKey> {
    const buffer = base64ToArrayBuffer(keyData);
    return await crypto.subtle.importKey(
        'raw',
        buffer,
        { name: 'AES-GCM', length: AES_KEY_LENGTH },
        false,
        ['encrypt', 'decrypt']
    );
}

/**
 * 获取或创建会话密钥
 */
async function getOrCreateSessionKey(): Promise<CryptoKey> {
    const storedKey = sessionStorage.getItem('app_session_key');
    if (storedKey) {
        try {
            return await importSessionKey(storedKey);
        } catch {
            sessionStorage.removeItem('app_session_key');
        }
    }
    const key = await generateSessionKey();
    const exported = await exportSessionKey(key);
    sessionStorage.setItem('app_session_key', exported);
    return key;
}

/**
 * 从 sessionStorage 获取已有的会话密钥
 */
async function getSessionKey(): Promise<CryptoKey | null> {
    const storedKey = sessionStorage.getItem('app_session_key');
    if (!storedKey) {
        return null;
    }
    try {
        return await importSessionKey(storedKey);
    } catch {
        sessionStorage.removeItem('app_session_key');
        return null;
    }
}

/**
 * 使用 AES-GCM 加密密码
 */
async function encryptPassword(password: string): Promise<string> {
    const sessionKey = await getOrCreateSessionKey();
    const encoder = new TextEncoder();
    const data = encoder.encode(password);

    const iv = crypto.getRandomValues(new Uint8Array(AES_IV_LENGTH));

    const encryptedBuffer = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv },
        sessionKey,
        data
    );

    // 将 IV 和密文拼接为 "iv:ciphertext" 格式（均为 base64）
    return arrayBufferToBase64(iv) + ':' + arrayBufferToBase64(encryptedBuffer);
}

/**
 * 使用 AES-GCM 解密密码
 */
async function decryptPassword(encrypted: string): Promise<string> {
    const sessionKey = await getSessionKey();
    if (!sessionKey) {
        throw new Error('会话密钥不存在，无法解密');
    }

    const [ivBase64, dataBase64] = encrypted.split(':');
    const iv = new Uint8Array(base64ToArrayBuffer(ivBase64));
    const encryptedData = new Uint8Array(base64ToArrayBuffer(dataBase64));

    const decryptedBuffer = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv },
        sessionKey,
        encryptedData
    );

    return new TextDecoder().decode(decryptedBuffer);
}

/**
 * 设置加密密钥（登录时调用）
 */
export async function setEncryptionKey(userId: string, password: string): Promise<void> {
    cachedUserId = userId;
    cachedPassword = password;
    
    // 将会话密钥加密后存储到 localStorage
    try {
        const encryptedPassword = await encryptPassword(password);
        localStorage.setItem(STORAGE_KEYS.SESSION_KEY + userId, encryptedPassword);
    } catch (error) {
        storageLogger.error('保存会话密钥失败:', error);
    }
}

/**
 * 尝试从会话中恢复加密密钥（页面刷新后调用）
 */
export async function restoreEncryptionKey(userId: string): Promise<boolean> {
    if (cachedPassword && cachedUserId === userId) {
        return true; // 已经恢复
    }
    
    try {
        const encryptedPassword = localStorage.getItem(STORAGE_KEYS.SESSION_KEY + userId);
        if (!encryptedPassword) {
            return false;
        }
        
        // 检查 sessionStorage 中是否有会话密钥
        if (!sessionStorage.getItem('app_session_key')) {
            return false; // 会话已过期（浏览器关闭后重新打开）
        }
        
        const password = await decryptPassword(encryptedPassword);
        cachedUserId = userId;
        cachedPassword = password;
        return true;
    } catch (error) {
        storageLogger.error('恢复会话密钥失败:', error);
        return false;
    }
}

/**
 * 清除加密密钥（登出时调用）
 */
export function clearEncryptionKey(): void {
    if (cachedUserId) {
        localStorage.removeItem(STORAGE_KEYS.SESSION_KEY + cachedUserId);
    }
    cachedPassword = null;
    cachedUserId = null;
    sessionStorage.removeItem('app_session_key');
}

/**
 * 检查是否已设置加密密钥
 */
export function hasEncryptionKey(): boolean {
    return cachedPassword !== null && cachedUserId !== null;
}

/**
 * 获取存储键
 */
function getStorageKey(userId: string, dataType: string): string {
    return `${STORAGE_KEYS.USER_DATA_PREFIX}${userId}_${dataType}`;
}

/**
 * 加密并存储数据
 */
export async function saveEncryptedData<T>(
    userId: string,
    dataType: string,
    data: T,
    password?: string
): Promise<void> {
    const key = password || cachedPassword;
    if (!key) {
        throw new Error('未设置加密密钥，请先登录');
    }

    const jsonData = JSON.stringify(data);
    const encrypted = await encryptData(jsonData, key);

    // 存储加密数据
    const storageKey = getStorageKey(userId, dataType);
    storageLogger.debug('保存加密数据:', { key: storageKey, length: jsonData.length });
    localStorage.setItem(storageKey, JSON.stringify(encrypted));
    storageLogger.debug('数据保存成功');

    // 标记加密已启用
    localStorage.setItem(STORAGE_KEYS.ENCRYPTION_ENABLED, 'true');
    localStorage.setItem(STORAGE_KEYS.DATA_VERSION, String(CURRENT_DATA_VERSION));
}

/**
 * 读取并解密数据
 */
export async function loadEncryptedData<T>(
    userId: string,
    dataType: string,
    password?: string
): Promise<T | null> {
    const key = password || cachedPassword;
    if (!key) {
        throw new Error('未设置加密密钥，请先登录');
    }

    const storageKey = getStorageKey(userId, dataType);
    const stored = localStorage.getItem(storageKey);

    if (!stored) {
        return null;
    }

    try {
        const encrypted: EncryptedData = JSON.parse(stored);

        // 检查是否是加密数据格式
        if (!isEncryptedData(encrypted)) {
            // 可能是旧版未加密数据，尝试直接解析
            return JSON.parse(stored) as T;
        }

        // 解密数据
        const decrypted = await decryptData(encrypted, key);
        if (decrypted === null) {
            throw new Error('解密失败，密码可能不正确');
        }

        return JSON.parse(decrypted) as T;
    } catch (error) {
        storageLogger.error(`加载加密数据失败 (${dataType}):`, error);
        return null;
    }
}

/**
 * 删除加密数据
 */
export function removeEncryptedData(userId: string, dataType: string): void {
    const storageKey = getStorageKey(userId, dataType);
    localStorage.removeItem(storageKey);
}

/**
 * 检查是否存在加密数据
 */
export function hasEncryptedData(userId: string, dataType: string): boolean {
    const storageKey = getStorageKey(userId, dataType);
    return localStorage.getItem(storageKey) !== null;
}

/**
 * 导出加密数据（用于备份）
 * 数据保持加密状态，即使导出文件被获取也无法解密
 */
export async function exportEncryptedData(userId: string): Promise<{
    version: number;
    timestamp: string;
    data: Record<string, EncryptedData | unknown>;
}> {
    const exported: Record<string, EncryptedData | unknown> = {};
    const prefix = STORAGE_KEYS.USER_DATA_PREFIX + userId;

    storageLogger.debug('导出加密数据，前缀:', prefix);

    for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
            const dataType = key.replace(prefix + '_', '');
            const stored = localStorage.getItem(key);
            storageLogger.debug('找到数据类型:', dataType);
            if (stored) {
                try {
                    exported[dataType] = JSON.parse(stored);
                } catch {
                    exported[dataType] = stored;
                }
            }
        }
    }

    storageLogger.debug('导出完成，数据类型数量:', Object.keys(exported).length);

    return {
        version: CURRENT_DATA_VERSION,
        timestamp: new Date().toISOString(),
        data: exported,
    };
}

/**
 * 导入加密数据（用于恢复）
 */
export async function importEncryptedData(
    userId: string,
    backup: {
        version: number;
        timestamp: string;
        data: Record<string, EncryptedData | unknown>;
    }
): Promise<void> {
    // 验证版本兼容性
    if (backup.version > CURRENT_DATA_VERSION) {
        throw new Error('备份文件版本不兼容');
    }

    // 导入数据
    for (const [dataType, data] of Object.entries(backup.data)) {
        const storageKey = getStorageKey(userId, dataType);
        localStorage.setItem(storageKey, JSON.stringify(data));
    }

    localStorage.setItem(STORAGE_KEYS.ENCRYPTION_ENABLED, 'true');
    localStorage.setItem(STORAGE_KEYS.DATA_VERSION, String(backup.version));
}

/**
 * 迁移旧数据到加密格式
 */
export async function migrateToEncrypted<T>(
    userId: string,
    dataType: string,
    oldData: T,
    password: string
): Promise<void> {
    await saveEncryptedData(userId, dataType, oldData, password);
}

/**
 * 清除所有用户数据
 */
export function clearAllUserData(userId: string): void {
    const prefix = STORAGE_KEYS.USER_DATA_PREFIX + userId;
    const keysToRemove: string[] = [];

    for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
            keysToRemove.push(key);
        }
    }

    keysToRemove.forEach(key => localStorage.removeItem(key));
}

/**
 * 检查是否启用了加密
 */
export function isEncryptionEnabled(): boolean {
    return localStorage.getItem(STORAGE_KEYS.ENCRYPTION_ENABLED) === 'true';
}
