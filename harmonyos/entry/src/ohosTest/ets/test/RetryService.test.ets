import { describe, expect, it } from '@ohos/hypium'
import { CircuitBreaker, CircuitBreakerConfig, RetryConfig, withRetry } from '../../../main/ets/services/http/RetryService'

export default function retryServiceTest(): void {
  describe('RetryServiceTest', () => {
    it('withRetry retries on retryable error', 0, async () => {
      const config = new RetryConfig()
      config.maxRetries = 2
      config.initialDelay = 1
      config.maxDelay = 5
      config.backoffFactor = 1
      config.retryableErrors = ['timeout']

      let attempts = 0
      const result = await withRetry<string>(
        async () => {
          attempts++
          if (attempts < 2) {
            throw new Error('timeout')
          }
          return 'ok'
        },
        'unit-test',
        config
      )
      expect(result).assertEqual('ok')
      expect(attempts).assertEqual(2)
    })

    it('CircuitBreaker opens after failures', 0, async () => {
      const config = new CircuitBreakerConfig()
      config.failureThreshold = 2
      config.resetTimeout = 1
      config.halfOpenMaxCalls = 1
      const breaker = new CircuitBreaker(config)

      let firstErrorMessage: string = ''
      try {
        await breaker.execute(async () => {
          throw new Error('fail')
        }, 'cb-test')
      } catch (err) {
        firstErrorMessage = err instanceof Error ? err.message : String(err)
      }
      expect(firstErrorMessage).assertContain('fail')

      let secondErrorMessage: string = ''
      try {
        await breaker.execute(async () => {
          throw new Error('fail')
        }, 'cb-test')
      } catch (err) {
        secondErrorMessage = err instanceof Error ? err.message : String(err)
      }
      expect(secondErrorMessage).assertContain('fail')

      expect(breaker.getState()).assertEqual('open')
    })
  })
}
