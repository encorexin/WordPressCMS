/**
 * API 层 - 使用加密数据存储
 * 此文件导出加密版本的 API，保持向后兼容
 */

// 从加密 API 重新导出所有内容
export * from './encryptedApi';

// 为了保持向后兼容，保留原有的类型导出
export type {
    Profile,
    WordPressSite,
    Article,
    UserRole,
    WordPressSiteInput,
    ArticleInput,
    ArticleWithSite,
} from './encryptedApi';
