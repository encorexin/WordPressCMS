import { aiLogger } from "./logger";

export interface RetryConfig {
    maxRetries: number;
    initialDelay: number;
    maxDelay: number;
    backoffFactor: number;
    retryableErrors: string[];
}

const DEFAULT_RETRY_CONFIG: RetryConfig = {
    maxRetries: 3,
    initialDelay: 1000,
    maxDelay: 30000,
    backoffFactor: 2,
    retryableErrors: [
        "ECONNRESET",
        "ENOTFOUND",
        "ETIMEDOUT",
        "ECONNABORTED",
        "network error",
        "fetch failed",
        "timeout",
        "rate limit",
        "429",
        "502",
        "503",
        "504",
    ],
};

function isRetryableError(error: unknown, retryableErrors: string[]): boolean {
    if (!error) return false;

    const errorString = error instanceof Error ? error.message.toLowerCase() : String(error).toLowerCase();

    return retryableErrors.some((retryable) => errorString.includes(retryable.toLowerCase()));
}

function calculateDelay(attempt: number, config: RetryConfig): number {
    const delay = config.initialDelay * Math.pow(config.backoffFactor, attempt - 1);
    const jitter = Math.random() * 0.3 * delay;
    return Math.min(delay + jitter, config.maxDelay);
}

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function withRetry<T>(
    fn: () => Promise<T>,
    operation: string,
    config: Partial<RetryConfig> = {}
): Promise<T> {
    const finalConfig = { ...DEFAULT_RETRY_CONFIG, ...config };
    let lastError: unknown;

    for (let attempt = 1; attempt <= finalConfig.maxRetries + 1; attempt++) {
        try {
            const result = await fn();
            if (attempt > 1) {
                aiLogger.info(`${operation} 重试成功 (第 ${attempt} 次)`);
            }
            return result;
        } catch (error) {
            lastError = error;

            if (attempt <= finalConfig.maxRetries && isRetryableError(error, finalConfig.retryableErrors)) {
                const delay = calculateDelay(attempt, finalConfig);
                aiLogger.warn(
                    `${operation} 失败，${Math.round(delay / 1000)}秒后重试 (第 ${attempt}/${finalConfig.maxRetries} 次)`,
                    error instanceof Error ? error.message : error
                );
                await sleep(delay);
            } else {
                break;
            }
        }
    }

    aiLogger.error(`${operation} 最终失败`, lastError);
    throw lastError;
}

export interface CircuitBreakerConfig {
    failureThreshold: number;
    resetTimeout: number;
    halfOpenMaxCalls: number;
}

const DEFAULT_CIRCUIT_BREAKER_CONFIG: CircuitBreakerConfig = {
    failureThreshold: 5,
    resetTimeout: 60000,
    halfOpenMaxCalls: 3,
};

type CircuitState = "closed" | "open" | "half-open";

class CircuitBreaker {
    private state: CircuitState = "closed";
    private failureCount = 0;
    private lastFailureTime = 0;
    private halfOpenCalls = 0;

    constructor(private config: CircuitBreakerConfig = DEFAULT_CIRCUIT_BREAKER_CONFIG) {}

    async execute<T>(fn: () => Promise<T>, operation: string): Promise<T> {
        if (this.state === "open") {
            const elapsed = Date.now() - this.lastFailureTime;
            if (elapsed >= this.config.resetTimeout) {
                aiLogger.info(`熔断器进入半开状态: ${operation}`);
                this.state = "half-open";
                this.halfOpenCalls = 0;
            } else {
                throw new Error(
                    `服务暂时不可用，请稍后重试 (${Math.round((this.config.resetTimeout - elapsed) / 1000)}秒后恢复)`
                );
            }
        }

        try {
            const result = await fn();

            if (this.state === "half-open") {
                this.halfOpenCalls++;
                if (this.halfOpenCalls >= this.config.halfOpenMaxCalls) {
                    aiLogger.info(`熔断器恢复正常: ${operation}`);
                    this.state = "closed";
                    this.failureCount = 0;
                }
            } else {
                this.failureCount = 0;
            }

            return result;
        } catch (error) {
            this.failureCount++;
            this.lastFailureTime = Date.now();

            if (this.state === "half-open") {
                aiLogger.warn(`熔断器重新打开: ${operation}`);
                this.state = "open";
            } else if (this.failureCount >= this.config.failureThreshold) {
                aiLogger.warn(`熔断器打开: ${operation} (失败次数: ${this.failureCount})`);
                this.state = "open";
            }

            throw error;
        }
    }

    getState(): CircuitState {
        return this.state;
    }

    reset(): void {
        this.state = "closed";
        this.failureCount = 0;
        this.lastFailureTime = 0;
        this.halfOpenCalls = 0;
    }
}

const circuitBreakers = new Map<string, CircuitBreaker>();

export function getCircuitBreaker(name: string, config?: CircuitBreakerConfig): CircuitBreaker {
    if (!circuitBreakers.has(name)) {
        circuitBreakers.set(name, new CircuitBreaker(config));
    }
    return circuitBreakers.get(name)!;
}

export async function withCircuitBreaker<T>(
    fn: () => Promise<T>,
    operation: string,
    circuitName = "default"
): Promise<T> {
    const circuitBreaker = getCircuitBreaker(circuitName);
    return circuitBreaker.execute(fn, operation);
}

export async function withRetryAndCircuitBreaker<T>(
    fn: () => Promise<T>,
    operation: string,
    retryConfig?: Partial<RetryConfig>,
    circuitName = "default"
): Promise<T> {
    return withCircuitBreaker(
        () => withRetry(fn, operation, retryConfig),
        operation,
        circuitName
    );
}

export interface RequestQueueConfig {
    maxConcurrent: number;
    maxQueueSize: number;
}

const DEFAULT_QUEUE_CONFIG: RequestQueueConfig = {
    maxConcurrent: 3,
    maxQueueSize: 100,
};

class RequestQueue {
    private queue: Array<() => Promise<void>> = [];
    private running = 0;

    constructor(private config: RequestQueueConfig = DEFAULT_QUEUE_CONFIG) {}

    async add<T>(fn: () => Promise<T>): Promise<T> {
        if (this.queue.length >= this.config.maxQueueSize) {
            throw new Error("请求队列已满，请稍后重试");
        }

        return new Promise((resolve, reject) => {
            const task = async () => {
                try {
                    const result = await fn();
                    resolve(result);
                } catch (error) {
                    reject(error);
                } finally {
                    this.running--;
                    this.processNext();
                }
            };

            this.queue.push(task);
            this.processNext();
        });
    }

    private processNext(): void {
        if (this.running >= this.config.maxConcurrent || this.queue.length === 0) {
            return;
        }

        this.running++;
        const task = this.queue.shift();
        if (task) {
            task();
        }
    }

    getStats(): { queueLength: number; running: number } {
        return {
            queueLength: this.queue.length,
            running: this.running,
        };
    }
}

const requestQueues = new Map<string, RequestQueue>();

export function getRequestQueue(name: string, config?: RequestQueueConfig): RequestQueue {
    if (!requestQueues.has(name)) {
        requestQueues.set(name, new RequestQueue(config));
    }
    return requestQueues.get(name)!;
}

export async function withQueue<T>(
    fn: () => Promise<T>,
    queueName = "default"
): Promise<T> {
    const queue = getRequestQueue(queueName);
    return queue.add(fn);
}

export async function withFullProtection<T>(
    fn: () => Promise<T>,
    operation: string,
    options?: {
        retryConfig?: Partial<RetryConfig>;
        circuitName?: string;
        queueName?: string;
    }
): Promise<T> {
    const queue = getRequestQueue(options?.queueName || "default");

    return queue.add(() =>
        withCircuitBreaker(
            () => withRetry(fn, operation, options?.retryConfig),
            operation,
            options?.circuitName || "default"
        )
    );
}
