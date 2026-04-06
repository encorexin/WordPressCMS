// SSE 事件流解析器 — 解析 AI 流式响应的 data: 行

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
  try {
    const parsed: Record<string, Object> = JSON.parse(data) as Record<string, Object>
    if (parsed['choices'] === undefined || parsed['choices'] === null) {
      return ''
    }
    const choices = parsed['choices'] as Record<string, Object>[]
    if (!Array.isArray(choices) || choices.length === 0) {
      return ''
    }
    const delta = choices[0]['delta']
    if (delta === undefined || delta === null || typeof delta !== 'object') {
      return ''
    }
    const content = (delta as Record<string, string>)['content']
    if (typeof content !== 'string') {
      return ''
    }
    return content
  } catch (_err) {
    return ''
  }
}
