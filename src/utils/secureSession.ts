import { cryptoLogger } from "./logger";

interface SecureSessionData {
    encryptedPassword: string;
    iv: string;
    salt: string;
    createdAt: number;
}

const SESSION_KEY_NAME = "secure_session_key";
const SESSION_DATA_PREFIX = "secure_session_";
const KEY_LENGTH = 256;
const IV_LENGTH = 12;
const SALT_LENGTH = 16;
const SESSION_EXPIRY_MS = 24 * 60 * 60 * 1000;

async function generateSessionKey(): Promise<CryptoKey> {
    return await crypto.subtle.generateKey(
        { name: "AES-GCM", length: KEY_LENGTH },
        true,
        ["encrypt", "decrypt"]
    );
}

async function exportKey(key: CryptoKey): Promise<string> {
    const exported = await crypto.subtle.exportKey("raw", key);
    return arrayBufferToBase64(exported);
}

async function importKey(keyData: string): Promise<CryptoKey> {
    const buffer = base64ToArrayBuffer(keyData);
    return await crypto.subtle.importKey(
        "raw",
        buffer,
        { name: "AES-GCM", length: KEY_LENGTH },
        false,
        ["encrypt", "decrypt"]
    );
}

function arrayBufferToBase64(buffer: ArrayBuffer | Uint8Array): string {
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
        binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
}

async function getSessionKey(): Promise<CryptoKey | null> {
    const storedKey = sessionStorage.getItem(SESSION_KEY_NAME);
    if (!storedKey) {
        return null;
    }

    try {
        return await importKey(storedKey);
    } catch {
        sessionStorage.removeItem(SESSION_KEY_NAME);
        return null;
    }
}

async function getOrCreateSessionKey(): Promise<CryptoKey> {
    let key = await getSessionKey();
    if (!key) {
        key = await generateSessionKey();
        const exportedKey = await exportKey(key);
        sessionStorage.setItem(SESSION_KEY_NAME, exportedKey);
        cryptoLogger.debug("新的会话密钥已创建");
    }
    return key;
}

async function encryptPasswordSecure(password: string): Promise<SecureSessionData> {
    const sessionKey = await getOrCreateSessionKey();
    const encoder = new TextEncoder();
    const data = encoder.encode(password);

    const salt = crypto.getRandomValues(new Uint8Array(SALT_LENGTH));
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));

    const keyMaterial = await crypto.subtle.importKey(
        "raw",
        data,
        { name: "PBKDF2" },
        false,
        ["deriveBits", "deriveKey"]
    );

    const derivedKey = await crypto.subtle.deriveKey(
        {
            name: "PBKDF2",
            salt: salt,
            iterations: 100000,
            hash: "SHA-256",
        },
        keyMaterial,
        { name: "AES-GCM", length: KEY_LENGTH },
        false,
        ["encrypt"]
    );

    const encryptedBuffer = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv: iv },
        derivedKey,
        encoder.encode(password)
    );

    return {
        encryptedPassword: arrayBufferToBase64(encryptedBuffer),
        iv: arrayBufferToBase64(iv),
        salt: arrayBufferToBase64(salt),
        createdAt: Date.now(),
    };
}

async function decryptPasswordSecure(sessionData: SecureSessionData): Promise<string> {
    const sessionKey = await getSessionKey();
    if (!sessionKey) {
        throw new Error("会话密钥不存在，请重新登录");
    }

    const iv = base64ToArrayBuffer(sessionData.iv);
    const salt = base64ToArrayBuffer(sessionData.salt);
    const encryptedData = base64ToArrayBuffer(sessionData.encryptedPassword);

    const decryptedBuffer = await crypto.subtle.decrypt(
        { name: "AES-GCM", iv: new Uint8Array(iv) },
        sessionKey,
        new Uint8Array(encryptedData)
    );

    const decoder = new TextDecoder();
    return decoder.decode(decryptedBuffer);
}

let cachedPassword: string | null = null;
let cachedUserId: string | null = null;

export async function setSecureEncryptionKey(userId: string, password: string): Promise<void> {
    cachedUserId = userId;
    cachedPassword = password;

    try {
        const sessionData = await encryptPasswordSecure(password);
        localStorage.setItem(
            SESSION_DATA_PREFIX + userId,
            JSON.stringify(sessionData)
        );
        cryptoLogger.info("安全加密密钥已设置");
    } catch (error) {
        cryptoLogger.error("保存安全会话密钥失败:", error);
        throw error;
    }
}

export async function restoreSecureEncryptionKey(userId: string): Promise<boolean> {
    if (cachedPassword && cachedUserId === userId) {
        return true;
    }

    try {
        const storedData = localStorage.getItem(SESSION_DATA_PREFIX + userId);
        if (!storedData) {
            cryptoLogger.debug("未找到存储的会话数据");
            return false;
        }

        const sessionData: SecureSessionData = JSON.parse(storedData);

        if (Date.now() - sessionData.createdAt > SESSION_EXPIRY_MS) {
            cryptoLogger.warn("会话已过期");
            localStorage.removeItem(SESSION_DATA_PREFIX + userId);
            return false;
        }

        const sessionKey = await getSessionKey();
        if (!sessionKey) {
            cryptoLogger.debug("会话密钥不存在（可能是新标签页）");
            return false;
        }

        const password = await decryptPasswordSecure(sessionData);
        cachedUserId = userId;
        cachedPassword = password;
        cryptoLogger.info("安全加密密钥已恢复");
        return true;
    } catch (error) {
        cryptoLogger.error("恢复安全会话密钥失败:", error);
        return false;
    }
}

export function clearSecureEncryptionKey(): void {
    if (cachedUserId) {
        localStorage.removeItem(SESSION_DATA_PREFIX + cachedUserId);
    }
    cachedPassword = null;
    cachedUserId = null;
    sessionStorage.removeItem(SESSION_KEY_NAME);
    cryptoLogger.info("安全加密密钥已清除");
}

export function hasSecureEncryptionKey(): boolean {
    return cachedPassword !== null && cachedUserId !== null;
}

export function getCachedPassword(): string | null {
    return cachedPassword;
}

export function getCachedUserId(): string | null {
    return cachedUserId;
}

export function isSessionExpired(userId: string): boolean {
    const storedData = localStorage.getItem(SESSION_DATA_PREFIX + userId);
    if (!storedData) return true;

    try {
        const sessionData: SecureSessionData = JSON.parse(storedData);
        return Date.now() - sessionData.createdAt > SESSION_EXPIRY_MS;
    } catch {
        return true;
    }
}

export function extendSession(userId: string): void {
    const storedData = localStorage.getItem(SESSION_DATA_PREFIX + userId);
    if (!storedData) return;

    try {
        const sessionData: SecureSessionData = JSON.parse(storedData);
        sessionData.createdAt = Date.now();
        localStorage.setItem(SESSION_DATA_PREFIX + userId, JSON.stringify(sessionData));
        cryptoLogger.debug("会话已延长");
    } catch (error) {
        cryptoLogger.error("延长会话失败:", error);
    }
}
