// 重试服务 - 指数退避、熔断器、请求队列

import { Logger } from '../../utils/Logger'

export class RetryConfig {
  maxRetries: number = 3
  initialDelay: number = 1000
  maxDelay: number = 30000
  backoffFactor: number = 2
  retryableErrors: string[] = [
    'ECONNRESET',
    'ENOTFOUND',
    'ETIMEDOUT',
    'ECONNABORTED',
    'network error',
    'fetch failed',
    'timeout',
    'rate limit',
    '429',
    '502',
    '503',
    '504'
  ]
}

export class CircuitBreakerConfig {
  failureThreshold: number = 5
  resetTimeout: number = 60000
  halfOpenMaxCalls: number = 3
}

export class RequestQueueConfig {
  maxConcurrent: number = 3
  maxQueueSize: number = 100
}

// 熔断器状态类型
type CircuitState = 'closed' | 'open' | 'half-open'

// 存储熔断器实例
const circuitBreakers: Map<string, CircuitBreaker> = new Map()

// 存储请求队列实例
const requestQueues: Map<string, RequestQueue> = new Map()

// 检查错误是否可重试
function isRetryableError(error: Error | string | null, retryableErrors: string[]): boolean {
  if (error === null || error === undefined) {
    return false
  }
  const errorString = typeof error === 'string' ? error.toLowerCase() : error.message.toLowerCase()
  for (let i = 0; i < retryableErrors.length; i++) {
    if (errorString.includes(retryableErrors[i].toLowerCase())) {
      return true
    }
  }
  return false
}

// 计算延迟时间（指数退避 + 抖动）
function calculateDelay(attempt: number, config: RetryConfig): number {
  const delay = config.initialDelay * Math.pow(config.backoffFactor, attempt - 1)
  const jitter = Math.random() * 0.3 * delay
  return Math.min(delay + jitter, config.maxDelay)
}

// 睡眠函数
function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve) => {
    setTimeout(() => {
      resolve()
    }, ms)
  })
}

// 带重试的执行
export async function withRetry<T>(
  fn: () => Promise<T>,
  operation: string,
  config?: RetryConfig
): Promise<T> {
  const finalConfig = config !== undefined ? config : new RetryConfig()
  let lastError: Error | null = null

  for (let attempt = 1; attempt <= finalConfig.maxRetries + 1; attempt++) {
    try {
      const result = await fn()
      if (attempt > 1) {
        Logger.info('%{public}s retry succeeded (attempt %{public}d)', operation, attempt.toString())
      }
      return result
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err))
      const shouldRetry = attempt <= finalConfig.maxRetries && isRetryableError(lastError, finalConfig.retryableErrors)
      if (shouldRetry) {
        const delay = calculateDelay(attempt, finalConfig)
        const delaySeconds = Math.round(delay / 1000)
        Logger.warn('%{public}s failed, retrying in %{public}ds (attempt %{public}d/%{public}d)', operation, delaySeconds.toString(), attempt.toString(), finalConfig.maxRetries.toString())
        await sleep(delay)
      } else {
        break
      }
    }
  }

  Logger.error('%{public}s finally failed: %{public}s', operation, lastError !== null ? lastError.message : 'Unknown error')
  throw lastError !== null ? lastError : new Error('Unknown error')
}

// 熔断器类
export class CircuitBreaker {
  private state: CircuitState = 'closed'
  private failureCount: number = 0
  private lastFailureTime: number = 0
  private halfOpenCalls: number = 0
  private config: CircuitBreakerConfig

  constructor(config?: CircuitBreakerConfig) {
    this.config = config !== undefined ? config : new CircuitBreakerConfig()
  }

  async execute<T>(fn: () => Promise<T>, operation: string): Promise<T> {
    if (this.state === 'open') {
      const elapsed = Date.now() - this.lastFailureTime
      if (elapsed >= this.config.resetTimeout) {
        Logger.info('Circuit breaker entering half-open: %{public}s', operation)
        this.state = 'half-open'
        this.halfOpenCalls = 0
      } else {
        const remaining = Math.round((this.config.resetTimeout - elapsed) / 1000)
        throw new Error('Service unavailable, retry in ' + remaining.toString() + 's')
      }
    }

    try {
      const result = await fn()
      if (this.state === 'half-open') {
        this.halfOpenCalls++
        if (this.halfOpenCalls >= this.config.halfOpenMaxCalls) {
          Logger.info('Circuit breaker recovered: %{public}s', operation)
          this.state = 'closed'
          this.failureCount = 0
        }
      } else {
        this.failureCount = 0
      }
      return result
    } catch (err) {
      this.failureCount++
      this.lastFailureTime = Date.now()
      if (this.state === 'half-open') {
        Logger.warn('Circuit breaker re-opened: %{public}s', operation)
        this.state = 'open'
      } else if (this.failureCount >= this.config.failureThreshold) {
        Logger.warn('Circuit breaker opened: %{public}s (failures: %{public}d)', operation, this.failureCount.toString())
        this.state = 'open'
      }
      throw err
    }
  }

  getState(): CircuitState {
    return this.state
  }

  reset(): void {
    this.state = 'closed'
    this.failureCount = 0
    this.lastFailureTime = 0
    this.halfOpenCalls = 0
  }
}

// 请求队列类
export class RequestQueue {
  private queue: Array<() => Promise<void>> = []
  private running: number = 0
  private config: RequestQueueConfig

  constructor(config?: RequestQueueConfig) {
    this.config = config !== undefined ? config : new RequestQueueConfig()
  }

  async add<T>(fn: () => Promise<T>): Promise<T> {
    if (this.queue.length >= this.config.maxQueueSize) {
      throw new Error('Request queue is full')
    }
    return new Promise<T>((resolve, reject) => {
      const task = async () => {
        try {
          const result = await fn()
          resolve(result)
        } catch (error) {
          reject(error)
        } finally {
          this.running--
          this.processNext()
        }
      }
      this.queue.push(task)
      this.processNext()
    })
  }

  private processNext(): void {
    if (this.running >= this.config.maxConcurrent || this.queue.length === 0) {
      return
    }
    this.running++
    const task = this.queue.shift()
    if (task !== undefined) {
      task()
    }
  }

  getStats(): { queueLength: number; running: number } {
    return {
      queueLength: this.queue.length,
      running: this.running
    }
  }
}

// 获取或创建熔断器实例
export function getCircuitBreaker(name: string, config?: CircuitBreakerConfig): CircuitBreaker {
  if (!circuitBreakers.has(name)) {
    circuitBreakers.set(name, new CircuitBreaker(config))
  }
  const breaker = circuitBreakers.get(name)
  if (breaker === undefined) {
    throw new Error('Circuit breaker not found')
  }
  return breaker
}

// 获取或创建请求队列实例
export function getRequestQueue(name: string, config?: RequestQueueConfig): RequestQueue {
  if (!requestQueues.has(name)) {
    requestQueues.set(name, new RequestQueue(config))
  }
  const queue = requestQueues.get(name)
  if (queue === undefined) {
    throw new Error('Request queue not found')
  }
  return queue
}

// 带熔断器的执行
export async function withCircuitBreaker<T>(
  fn: () => Promise<T>,
  operation: string,
  circuitName: string = 'default'
): Promise<T> {
  const breaker = getCircuitBreaker(circuitName)
  return breaker.execute(fn, operation)
}

// 带队列的执行
export async function withQueue<T>(
  fn: () => Promise<T>,
  queueName: string = 'default'
): Promise<T> {
  const queue = getRequestQueue(queueName)
  return queue.add(fn)
}

// 完整保护：队列 + 熔断器 + 重试
export async function withFullProtection<T>(
  fn: () => Promise<T>,
  operation: string,
  options?: {
    retryConfig?: RetryConfig
    circuitName?: string
    queueName?: string
  }
): Promise<T> {
  const queue = getRequestQueue(options?.queueName !== undefined ? options.queueName : 'default')
  return queue.add(() =>
    withCircuitBreaker(
      () => withRetry(fn, operation, options?.retryConfig),
      operation,
      options?.circuitName !== undefined ? options.circuitName : 'default'
    )
  )
}
