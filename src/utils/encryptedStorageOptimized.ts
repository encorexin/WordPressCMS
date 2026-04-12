import { encryptData, decryptData, isEncryptedData, type EncryptedData } from "./crypto";
import { cryptoLogger } from "./logger";

const STORAGE_KEYS = {
    USER_DATA_PREFIX: "encrypted_data_",
    ENCRYPTION_ENABLED: "encryption_enabled",
    DATA_VERSION: "data_version",
    SESSION_KEY: "session_key_",
} as const;

const CURRENT_DATA_VERSION = 1;

type CacheEntry<T> = {
    data: T;
    timestamp: number;
    dirty: boolean;
};

class EncryptedDataCache {
    private cache = new Map<string, CacheEntry<unknown>>();
    private ttl: number;
    private maxEntries: number;

    constructor(ttl = 5 * 60 * 1000, maxEntries = 50) {
        this.ttl = ttl;
        this.maxEntries = maxEntries;
    }

    private getCacheKey(userId: string, dataType: string): string {
        return `${userId}:${dataType}`;
    }

    get<T>(userId: string, dataType: string): T | null {
        const key = this.getCacheKey(userId, dataType);
        const entry = this.cache.get(key) as CacheEntry<T> | undefined;

        if (!entry) {
            return null;
        }

        if (Date.now() - entry.timestamp > this.ttl) {
            this.cache.delete(key);
            return null;
        }

        cryptoLogger.debug(`缓存命中: ${dataType}`);
        return entry.data;
    }

    set<T>(userId: string, dataType: string, data: T, dirty = false): void {
        const key = this.getCacheKey(userId, dataType);

        if (this.cache.size >= this.maxEntries && !this.cache.has(key)) {
            const oldestKey = this.cache.keys().next().value;
            if (oldestKey) {
                this.cache.delete(oldestKey);
            }
        }

        this.cache.set(key, {
            data,
            timestamp: Date.now(),
            dirty,
        });

        cryptoLogger.debug(`缓存设置: ${dataType}`);
    }

    invalidate(userId: string, dataType: string): void {
        const key = this.getCacheKey(userId, dataType);
        this.cache.delete(key);
        cryptoLogger.debug(`缓存失效: ${dataType}`);
    }

    invalidateAll(userId: string): void {
        const prefix = `${userId}:`;
        for (const key of this.cache.keys()) {
            if (key.startsWith(prefix)) {
                this.cache.delete(key);
            }
        }
        cryptoLogger.debug(`用户缓存全部失效: ${userId}`);
    }

    isDirty(userId: string, dataType: string): boolean {
        const key = this.getCacheKey(userId, dataType);
        const entry = this.cache.get(key);
        return entry?.dirty ?? false;
    }

    markClean(userId: string, dataType: string): void {
        const key = this.getCacheKey(userId, dataType);
        const entry = this.cache.get(key);
        if (entry) {
            entry.dirty = false;
        }
    }

    clear(): void {
        this.cache.clear();
        cryptoLogger.debug("缓存已清空");
    }
}

const dataCache = new EncryptedDataCache();

let cachedPassword: string | null = null;
let cachedUserId: string | null = null;

async function generateSessionKey(): Promise<string> {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return Array.from(array, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

function getSessionKey(): string {
    let sessionKey = sessionStorage.getItem("app_session_key");
    if (!sessionKey) {
        sessionKey = Array.from(crypto.getRandomValues(new Uint8Array(32)), (b) =>
            b.toString(16).padStart(2, "0")
        ).join("");
        sessionStorage.setItem("app_session_key", sessionKey);
    }
    return sessionKey;
}

async function encryptPassword(password: string): Promise<string> {
    const sessionKey = getSessionKey();
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    const keyBytes = encoder.encode(sessionKey.slice(0, 32));
    const encrypted = new Uint8Array(data.length);
    for (let i = 0; i < data.length; i++) {
        encrypted[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    return btoa(String.fromCharCode(...encrypted));
}

async function decryptPassword(encrypted: string): Promise<string> {
    const sessionKey = getSessionKey();
    const decoder = new TextDecoder();
    const encoder = new TextEncoder();
    const encryptedBytes = Uint8Array.from(atob(encrypted), (c) => c.charCodeAt(0));
    const keyBytes = encoder.encode(sessionKey.slice(0, 32));
    const decrypted = new Uint8Array(encryptedBytes.length);
    for (let i = 0; i < encryptedBytes.length; i++) {
        decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return decoder.decode(decrypted);
}

export async function setEncryptionKey(userId: string, password: string): Promise<void> {
    cachedUserId = userId;
    cachedPassword = password;

    try {
        const encryptedPassword = await encryptPassword(password);
        localStorage.setItem(STORAGE_KEYS.SESSION_KEY + userId, encryptedPassword);
        cryptoLogger.info("加密密钥已设置");
    } catch (error) {
        cryptoLogger.error("保存会话密钥失败:", error);
    }
}

export async function restoreEncryptionKey(userId: string): Promise<boolean> {
    if (cachedPassword && cachedUserId === userId) {
        return true;
    }

    try {
        const encryptedPassword = localStorage.getItem(STORAGE_KEYS.SESSION_KEY + userId);
        if (!encryptedPassword) {
            return false;
        }

        if (!sessionStorage.getItem("app_session_key")) {
            return false;
        }

        const password = await decryptPassword(encryptedPassword);
        cachedUserId = userId;
        cachedPassword = password;
        cryptoLogger.info("加密密钥已恢复");
        return true;
    } catch (error) {
        cryptoLogger.error("恢复会话密钥失败:", error);
        return false;
    }
}

export function clearEncryptionKey(): void {
    if (cachedUserId) {
        localStorage.removeItem(STORAGE_KEYS.SESSION_KEY + cachedUserId);
    }
    cachedPassword = null;
    cachedUserId = null;
    sessionStorage.removeItem("app_session_key");
    dataCache.clear();
    cryptoLogger.info("加密密钥已清除");
}

export function hasEncryptionKey(): boolean {
    return cachedPassword !== null && cachedUserId !== null;
}

function getStorageKey(userId: string, dataType: string): string {
    return `${STORAGE_KEYS.USER_DATA_PREFIX}${userId}_${dataType}`;
}

export async function saveEncryptedData<T>(
    userId: string,
    dataType: string,
    data: T,
    password?: string
): Promise<void> {
    const key = password || cachedPassword;
    if (!key) {
        throw new Error("未设置加密密钥，请先登录");
    }

    cryptoLogger.time(`加密保存 ${dataType}`);

    const jsonData = JSON.stringify(data);
    const encrypted = await encryptData(jsonData, key);

    const storageKey = getStorageKey(userId, dataType);
    localStorage.setItem(storageKey, JSON.stringify(encrypted));

    dataCache.set(userId, dataType, data, false);

    localStorage.setItem(STORAGE_KEYS.ENCRYPTION_ENABLED, "true");
    localStorage.setItem(STORAGE_KEYS.DATA_VERSION, String(CURRENT_DATA_VERSION));

    cryptoLogger.timeEnd(`加密保存 ${dataType}`);
    cryptoLogger.debug(`数据已保存: ${dataType}, 大小: ${jsonData.length} 字节`);
}

export async function loadEncryptedData<T>(
    userId: string,
    dataType: string,
    password?: string,
    useCache = true
): Promise<T | null> {
    if (useCache) {
        const cached = dataCache.get<T>(userId, dataType);
        if (cached !== null) {
            return cached;
        }
    }

    const key = password || cachedPassword;
    if (!key) {
        throw new Error("未设置加密密钥，请先登录");
    }

    const storageKey = getStorageKey(userId, dataType);
    const stored = localStorage.getItem(storageKey);

    if (!stored) {
        return null;
    }

    try {
        cryptoLogger.time(`加密加载 ${dataType}`);

        const encrypted: EncryptedData = JSON.parse(stored);

        if (!isEncryptedData(encrypted)) {
            const data = JSON.parse(stored) as T;
            dataCache.set(userId, dataType, data);
            return data;
        }

        const decrypted = await decryptData(encrypted, key);
        if (decrypted === null) {
            throw new Error("解密失败，密码可能不正确");
        }

        const data = JSON.parse(decrypted) as T;
        dataCache.set(userId, dataType, data);

        cryptoLogger.timeEnd(`加密加载 ${dataType}`);
        return data;
    } catch (error) {
        cryptoLogger.error(`加载加密数据失败 (${dataType}):`, error);
        return null;
    }
}

export function removeEncryptedData(userId: string, dataType: string): void {
    const storageKey = getStorageKey(userId, dataType);
    localStorage.removeItem(storageKey);
    dataCache.invalidate(userId, dataType);
    cryptoLogger.debug(`数据已删除: ${dataType}`);
}

export function hasEncryptedData(userId: string, dataType: string): boolean {
    const storageKey = getStorageKey(userId, dataType);
    return localStorage.getItem(storageKey) !== null;
}

export async function exportEncryptedData(userId: string): Promise<{
    version: number;
    timestamp: string;
    data: Record<string, EncryptedData | unknown>;
}> {
    const exported: Record<string, EncryptedData | unknown> = {};
    const prefix = STORAGE_KEYS.USER_DATA_PREFIX + userId;

    for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
            const dataType = key.replace(prefix + "_", "");
            const stored = localStorage.getItem(key);
            if (stored) {
                try {
                    exported[dataType] = JSON.parse(stored);
                } catch {
                    exported[dataType] = stored;
                }
            }
        }
    }

    return {
        version: CURRENT_DATA_VERSION,
        timestamp: new Date().toISOString(),
        data: exported,
    };
}

export async function importEncryptedData(
    userId: string,
    backup: {
        version: number;
        timestamp: string;
        data: Record<string, EncryptedData | unknown>;
    }
): Promise<void> {
    if (backup.version > CURRENT_DATA_VERSION) {
        throw new Error("备份文件版本不兼容");
    }

    for (const [dataType, data] of Object.entries(backup.data)) {
        const storageKey = getStorageKey(userId, dataType);
        localStorage.setItem(storageKey, JSON.stringify(data));
    }

    dataCache.invalidateAll(userId);

    localStorage.setItem(STORAGE_KEYS.ENCRYPTION_ENABLED, "true");
    localStorage.setItem(STORAGE_KEYS.DATA_VERSION, String(backup.version));
}

export async function migrateToEncrypted<T>(
    userId: string,
    dataType: string,
    oldData: T,
    password: string
): Promise<void> {
    await saveEncryptedData(userId, dataType, oldData, password);
}

export function clearAllUserData(userId: string): void {
    const prefix = STORAGE_KEYS.USER_DATA_PREFIX + userId;
    const keysToRemove: string[] = [];

    for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(prefix)) {
            keysToRemove.push(key);
        }
    }

    keysToRemove.forEach((key) => {
        localStorage.removeItem(key);
    });
    dataCache.invalidateAll(userId);
}

export function isEncryptionEnabled(): boolean {
    return localStorage.getItem(STORAGE_KEYS.ENCRYPTION_ENABLED) === "true";
}

export function invalidateCache(userId: string, dataType: string): void {
    dataCache.invalidate(userId, dataType);
}

export function invalidateAllCache(userId: string): void {
    dataCache.invalidateAll(userId);
}

export function getCacheStats(): { size: number; maxEntries: number } {
    return {
        size: (dataCache as unknown as { cache: Map<string, unknown> }).cache.size,
        maxEntries: 50,
    };
}
