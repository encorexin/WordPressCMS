/**
 * 加密服务 - 基于用户密码的数据加密
 * 使用 PBKDF2 派生密钥，AES-GCM 加密
 */

import { cryptoLogger } from './logger';

// 加密常量
const PBKDF2_ITERATIONS = 100000;
const SALT_LENGTH = 16;
const IV_LENGTH = 12;
const KEY_LENGTH = 256;

// 加密数据格式
export interface EncryptedData {
    salt: string;      // Base64 编码的盐
    iv: string;        // Base64 编码的初始化向量
    data: string;      // Base64 编码的密文
    version: number;   // 加密版本，用于向后兼容
}

/**
 * 从密码派生加密密钥
 */
async function deriveKey(password: string, salt: Uint8Array): Promise<CryptoKey> {
    const encoder = new TextEncoder();
    const passwordBuffer = encoder.encode(password);

    // 导入密码作为原始密钥材料
    const keyMaterial = await crypto.subtle.importKey(
        'raw',
        passwordBuffer,
        { name: 'PBKDF2' },
        false,
        ['deriveBits', 'deriveKey']
    );

    // 使用 PBKDF2 派生 AES-GCM 密钥
    return crypto.subtle.deriveKey(
        {
            name: 'PBKDF2',
            salt: salt,
            iterations: PBKDF2_ITERATIONS,
            hash: 'SHA-256',
        },
        keyMaterial,
        { name: 'AES-GCM', length: KEY_LENGTH },
        false,
        ['encrypt', 'decrypt']
    );
}

/**
 * 加密数据
 * @param data 要加密的字符串数据
 * @param password 用户密码
 * @returns 加密后的数据对象
 */
export async function encryptData(data: string, password: string): Promise<EncryptedData> {
    const encoder = new TextEncoder();
    const dataBuffer = encoder.encode(data);

    // 生成随机盐和 IV
    const salt = crypto.getRandomValues(new Uint8Array(SALT_LENGTH));
    const iv = crypto.getRandomValues(new Uint8Array(IV_LENGTH));

    // 派生密钥
    const key = await deriveKey(password, salt);

    // 加密数据
    const encryptedBuffer = await crypto.subtle.encrypt(
        { name: 'AES-GCM', iv: iv },
        key,
        dataBuffer
    );

    // 转换为 Base64
    return {
        salt: arrayBufferToBase64(salt),
        iv: arrayBufferToBase64(iv),
        data: arrayBufferToBase64(encryptedBuffer),
        version: 1,
    };
}

/**
 * 解密数据
 * @param encryptedData 加密的数据对象
 * @param password 用户密码
 * @returns 解密后的字符串，失败返回 null
 */
export async function decryptData(encryptedData: EncryptedData, password: string): Promise<string | null> {
    try {
        // 从 Base64 解码
        const salt = base64ToArrayBuffer(encryptedData.salt);
        const iv = base64ToArrayBuffer(encryptedData.iv);
        const data = base64ToArrayBuffer(encryptedData.data);

        // 派生密钥
        const key = await deriveKey(password, new Uint8Array(salt));

        // 解密数据
        const decryptedBuffer = await crypto.subtle.decrypt(
            { name: 'AES-GCM', iv: new Uint8Array(iv) },
            key,
            data
        );

        // 解码为字符串
        const decoder = new TextDecoder();
        return decoder.decode(decryptedBuffer);
    } catch (error) {
        cryptoLogger.error('解密失败:', error);
        return null;
    }
}

/**
 * 检查数据是否已加密
 */
export function isEncryptedData(data: unknown): data is EncryptedData {
    return (
        typeof data === 'object' &&
        data !== null &&
        'salt' in data &&
        'iv' in data &&
        'data' in data &&
        'version' in data
    );
}

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
 * 生成数据哈希（用于验证数据完整性）
 */
export async function generateHash(data: string): Promise<string> {
    const encoder = new TextEncoder();
    const dataBuffer = encoder.encode(data);
    const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer);
    return arrayBufferToBase64(hashBuffer);
}
