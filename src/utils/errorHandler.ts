import { toast } from "sonner";

export interface AppError {
    code: string;
    message: string;
    details?: unknown;
}

export type Result<T, E = AppError> =
    | { success: true; data: T }
    | { success: false; error: E };

export const ErrorCodes = {
    UNAUTHORIZED: "UNAUTHORIZED",
    NOT_FOUND: "NOT_FOUND",
    VALIDATION_ERROR: "VALIDATION_ERROR",
    NETWORK_ERROR: "NETWORK_ERROR",
    ENCRYPTION_ERROR: "ENCRYPTION_ERROR",
    DATABASE_ERROR: "DATABASE_ERROR",
    API_ERROR: "API_ERROR",
    UNKNOWN: "UNKNOWN",
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

export class AppException extends Error {
    constructor(
        public code: ErrorCode,
        message: string,
        public details?: unknown
    ) {
        super(message);
        this.name = "AppException";
    }

    toAppError(): AppError {
        return {
            code: this.code,
            message: this.message,
            details: this.details,
        };
    }
}

export function createError(code: ErrorCode, message: string, details?: unknown): AppError {
    return { code, message, details };
}

export function isSuccess<T>(result: Result<T>): result is { success: true; data: T } {
    return result.success === true;
}

export function isFailure<T>(result: Result<T>): result is { success: false; error: AppError } {
    return result.success === false;
}

export function handleApiError(error: unknown, operation: string): AppError {
    console.error(`${operation}失败:`, error);

    if (error instanceof AppException) {
        toast.error(`${operation}失败: ${error.message}`);
        return error.toAppError();
    }

    if (error instanceof Error) {
        const message = error.message || "未知错误";
        toast.error(`${operation}失败: ${message}`);
        return createError(ErrorCodes.UNKNOWN, message, error);
    }

    const message = "发生未知错误";
    toast.error(`${operation}失败: ${message}`);
    return createError(ErrorCodes.UNKNOWN, message, error);
}

export function handleDatabaseError(error: unknown, operation: string): AppError {
    console.error(`数据库操作失败 [${operation}]:`, error);
    const message = error instanceof Error ? error.message : "数据库操作失败";
    toast.error(`${operation}失败: ${message}`);
    return createError(ErrorCodes.DATABASE_ERROR, message, error);
}

export function handleEncryptionError(error: unknown, operation: string): AppError {
    console.error(`加密操作失败 [${operation}]:`, error);
    const message = error instanceof Error ? error.message : "加密操作失败";
    toast.error(`${operation}失败: ${message}`);
    return createError(ErrorCodes.ENCRYPTION_ERROR, message, error);
}

export function handleNetworkError(error: unknown, operation: string): AppError {
    console.error(`网络请求失败 [${operation}]:`, error);

    let message = "网络请求失败";
    if (error instanceof Error) {
        if (error.name === "AbortError") {
            message = "请求已取消";
        } else if (error.message.includes("fetch")) {
            message = "网络连接失败，请检查网络设置";
        } else {
            message = error.message;
        }
    }

    toast.error(`${operation}失败: ${message}`);
    return createError(ErrorCodes.NETWORK_ERROR, message, error);
}

export function tryCatch<T>(
    fn: () => T,
    operation: string,
    errorHandler: typeof handleApiError = handleApiError
): Result<T> {
    try {
        const data = fn();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: errorHandler(error, operation) };
    }
}

export async function tryCatchAsync<T>(
    fn: () => Promise<T>,
    operation: string,
    errorHandler: typeof handleApiError = handleApiError
): Promise<Result<T>> {
    try {
        const data = await fn();
        return { success: true, data };
    } catch (error) {
        return { success: false, error: errorHandler(error, operation) };
    }
}

export function unwrapOr<T>(result: Result<T>, defaultValue: T): T {
    return result.success ? result.data : defaultValue;
}

export function unwrap<T>(result: Result<T>): T {
    if (result.success === false) {
        throw new AppException(
            result.error.code as ErrorCode,
            result.error.message,
            result.error.details
        );
    }
    return result.data;
}
