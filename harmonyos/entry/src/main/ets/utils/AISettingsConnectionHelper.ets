// AI 设置连接测试辅助方法

import { AIStreamClient, ChatMessage } from '../services/http/AIStreamClient'

export class AISettingsConnectionHelper {
  static async requestConnectionPreview(endpoint: string, apiKey: string, model: string): Promise<string> {
    const messages: ChatMessage[] = []
    const message = new ChatMessage()
    message.role = 'user'
    message.content = 'Hello, this is a connection test. Please reply with "OK" only.'
    messages.push(message)
    return AIStreamClient.sendOnce(endpoint, apiKey, model, messages)
  }

  static formatPreview(result: string): string {
    return result.length > 80 ? result.substring(0, 80) + '...' : result
  }

  static formatError(errorText: string): string {
    return errorText.length > 100 ? errorText.substring(0, 100) + '...' : errorText
  }
}
