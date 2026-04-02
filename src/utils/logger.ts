type LogLevel = "debug" | "info" | "warn" | "error";

interface LogEntry {
    level: LogLevel;
    timestamp: string;
    module: string;
    message: string;
    data?: unknown;
}

const isDev = import.meta.env.DEV;

const LOG_COLORS: Record<LogLevel, string> = {
    debug: "color: #6b7280",
    info: "color: #3b82f6",
    warn: "color: #f59e0b",
    error: "color: #ef4444",
};

const LOG_PREFIXES: Record<LogLevel, string> = {
    debug: "🔍",
    info: "ℹ️",
    warn: "⚠️",
    error: "❌",
};

class Logger {
    private module: string;
    private enableConsole: boolean;
    private logBuffer: LogEntry[] = [];
    private maxBufferSize = 100;

    constructor(module: string, enableConsole = isDev) {
        this.module = module;
        this.enableConsole = enableConsole;
    }

    private formatTimestamp(): string {
        return new Date().toISOString().split("T")[1].slice(0, 12);
    }

    private log(level: LogLevel, message: string, data?: unknown): void {
        const entry: LogEntry = {
            level,
            timestamp: new Date().toISOString(),
            module: this.module,
            message,
            data,
        };

        if (this.logBuffer.length >= this.maxBufferSize) {
            this.logBuffer.shift();
        }
        this.logBuffer.push(entry);

        if (this.enableConsole) {
            const prefix = `${LOG_PREFIXES[level]} [${this.formatTimestamp()}] [${this.module}]`;
            const style = LOG_COLORS[level];

            if (data !== undefined) {
                console[level](
                    `%c${prefix} ${message}`,
                    style,
                    data
                );
            } else {
                console[level](`%c${prefix} ${message}`, style);
            }
        }
    }

    debug(message: string, data?: unknown): void {
        this.log("debug", message, data);
    }

    info(message: string, data?: unknown): void {
        this.log("info", message, data);
    }

    warn(message: string, data?: unknown): void {
        this.log("warn", message, data);
    }

    error(message: string, data?: unknown): void {
        this.log("error", message, data);
    }

    time(label: string): void {
        if (this.enableConsole) {
            console.time(`[${this.module}] ${label}`);
        }
    }

    timeEnd(label: string): void {
        if (this.enableConsole) {
            console.timeEnd(`[${this.module}] ${label}`);
        }
    }

    group(label: string): void {
        if (this.enableConsole) {
            console.group(`[${this.module}] ${label}`);
        }
    }

    groupEnd(): void {
        if (this.enableConsole) {
            console.groupEnd();
        }
    }

    getBuffer(): LogEntry[] {
        return [...this.logBuffer];
    }

    clearBuffer(): void {
        this.logBuffer = [];
    }

    exportLogs(): string {
        return JSON.stringify(this.logBuffer, null, 2);
    }
}

const loggers = new Map<string, Logger>();

export function createLogger(module: string): Logger {
    if (loggers.has(module)) {
        return loggers.get(module)!;
    }

    const logger = new Logger(module);
    loggers.set(module, logger);
    return logger;
}

export const authLogger = createLogger("Auth");
export const dbLogger = createLogger("Database");
export const apiLogger = createLogger("API");
export const cryptoLogger = createLogger("Crypto");
export const aiLogger = createLogger("AI");
export const wpLogger = createLogger("WordPress");
export const storageLogger = createLogger("Storage");

export const logger = createLogger("App");

export default createLogger;
