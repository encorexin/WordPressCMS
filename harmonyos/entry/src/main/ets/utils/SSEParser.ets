// SSE 事件流解析器 — 解析 AI 流式响应的 data: 行

import { Logger } from './Logger'

interface SSEDeltaPayload {
  content?: string
}

interface SSEChoicePayload {
  delta?: SSEDeltaPayload
}

interface SSEUsagePayload {
  total_tokens?: number | string
}

interface SSEPayload {
  choices?: SSEChoicePayload[]
  usage?: SSEUsagePayload
}

export class SSEEvent {
  event: string = ''
  data: string = ''
  id: string = ''
}

export class SSEParser {
  private buffer: string = ''
  private currentEvent: SSEEvent = new SSEEvent()
  private static readonly MAX_BUFFER_SIZE: number = 1048576

  parse(chunk: string): SSEEvent[] {
    this.buffer += chunk
    if (this.buffer.length > SSEParser.MAX_BUFFER_SIZE) {
      Logger.warn('SSEParser.parse buffer overflow: %{public}s', String(this.buffer.length))
      this.buffer = ''
      return []
    }
    const events: SSEEvent[] = []
    const lines = this.buffer.split('\n')

    // 保留最后一个不完整的行
    this.buffer = lines[lines.length - 1]

    for (let i = 0; i < lines.length - 1; i++) {
      const line = lines[i].trim()

      if (line.length === 0) {
        // 空行表示一个事件结束
        if (this.currentEvent.data.length > 0) {
          events.push(this.currentEvent)
          this.currentEvent = new SSEEvent()
        }
        continue
      }

      if (line.startsWith('data:')) {
        const value = line.substring(5).trim()
        if (this.currentEvent.data.length > 0) {
          this.currentEvent.data += '\n' + value
        } else {
          this.currentEvent.data = value
        }
      } else if (line.startsWith('event:')) {
        this.currentEvent.event = line.substring(6).trim()
      } else if (line.startsWith('id:')) {
        this.currentEvent.id = line.substring(3).trim()
      }
    }

    return events
  }

  reset(): void {
    this.buffer = ''
    this.currentEvent = new SSEEvent()
  }
}

// 从 SSE data 中提取 OpenAI 兼容格式的 delta content
export function extractDeltaContent(data: string): string {
  if (data === '[DONE]') {
    return ''
  }
  const parsed = parsePayload(data)
  if (parsed === null || !Array.isArray(parsed.choices) || parsed.choices.length === 0) {
    return ''
  }
  const firstChoice = parsed.choices[0]
  if (firstChoice.delta === undefined || typeof firstChoice.delta.content !== 'string') {
    return ''
  }
  return firstChoice.delta.content
}

export function extractUsageTotalTokens(data: string): number {
  if (data === '[DONE]') {
    return 0
  }
  const parsed = parsePayload(data)
  if (parsed === null || parsed.usage === undefined) {
    return 0
  }
  const total = parsed.usage.total_tokens
  if (typeof total === 'number') {
    return total
  }
  if (typeof total === 'string') {
    const n = Number(total)
    return Number.isFinite(n) ? n : 0
  }
  return 0
}

function parsePayload(data: string): SSEPayload | null {
  try {
    return JSON.parse(data) as SSEPayload
  } catch (parseErr) {
    Logger.debug('SSEParser.parsePayload skipped malformed chunk: %{public}s', String(parseErr))
    return null
  }
}
