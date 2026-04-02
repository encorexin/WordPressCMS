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

// 内存中缓存的解密密钥
let cachedPassword: string | null = null;
let cachedUserId: string | null = null;

/**
 * 生成会话密钥（用于加密存储密码）
 */
function generateSessionKey(): string {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * 获取或创建会话密钥
 */
function getSessionKey(): string {
    let sessionKey = sessionStorage.getItem('app_session_key');
    if (!sessionKey) {
        sessionKey = generateSessionKey();
        sessionStorage.setItem('app_session_key', sessionKey);
    }
    return sessionKey;
}

/**
 * 使用会话密钥加密密码
 */
async function encryptPassword(password: string): Promise<string> {
    const sessionKey = getSessionKey();
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    
    // 使用简单的 XOR 加密（因为密钥只在内存和 sessionStorage 中）
    const keyBytes = encoder.encode(sessionKey.slice(0, 32));
    const encrypted = new Uint8Array(data.length);
    for (let i = 0; i < data.length; i++) {
        encrypted[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return btoa(String.fromCharCode(...encrypted));
}

/**
 * 使用会话密钥解密密码
 */
async function decryptPassword(encrypted: string): Promise<string> {
    const sessionKey = getSessionKey();
    const decoder = new TextDecoder();
    const encoder = new TextEncoder();
    
    const encryptedBytes = Uint8Array.from(atob(encrypted), c => c.charCodeAt(0));
    const keyBytes = encoder.encode(sessionKey.slice(0, 32));
    
    const decrypted = new Uint8Array(encryptedBytes.length);
    for (let i = 0; i < encryptedBytes.length; i++) {
        decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return decoder.decode(decrypted);
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
