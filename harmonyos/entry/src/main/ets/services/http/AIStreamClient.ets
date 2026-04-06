// AI 流式请求客户端 — SSE 解析 + 流式 UI 更新

import http from '@ohos.net.http'
import util from '@ohos.util'
import { HttpClient } from './HttpClient'
import { SSEParser, extractDeltaContent } from '../../utils/SSEParser'
import { Logger } from '../../utils/Logger'

// 聊天消息
export class ChatMessage {
  role: string = 'user'  // user | assistant | system
  content: string = ''
}

// 流式选项
export class StreamOptions {
  endpoint: string = ''
  apiKey: string = ''
  model: string = ''
  messages: ChatMessage[] = []
  onUpdate: (content: string) => void = () => {}
  onComplete: () => void = () => {}
  onError: (error: string) => void = () => {}
}

export class AIStreamClient {

  // 发起 AI 流式对话
  static sendStream(options: StreamOptions): http.HttpRequest {
    let currentContent = ''
    const parser = new SSEParser()

    // 构建请求头
    const headers: Record<string, string> = {}
    if (options.apiKey.length > 0) {
      headers['Authorization'] = `Bearer ${options.apiKey}`
    }

    // 构建请求体
    const messagesArr: Record<string, string>[] = []
    for (let i = 0; i < options.messages.length; i++) {
      const msg = options.messages[i]
      const item: Record<string, string> = {
        'role': msg.role,
        'content': msg.content
      }
      messagesArr.push(item)
    }

    const bodyObj: Record<string, Object> = {
      'messages': messagesArr,
      'stream': true
    }
    if (options.model.length > 0) {
      bodyObj['model'] = options.model
    }

    const body = JSON.stringify(bodyObj)
    const decoder = new util.TextDecoder('utf-8')

    const httpRequest = HttpClient.requestStream(
      options.endpoint,
      body,
      headers,
      (chunk: ArrayBuffer) => {
        // 解码数据块
        const text = decoder.decodeToString(new Uint8Array(chunk))

        // SSE 解析
        const events = parser.parse(text)
        for (let i = 0; i < events.length; i++) {
          const event = events[i]
          if (event.data === '[DONE]') {
            continue
          }
          const delta = extractDeltaContent(event.data)
          if (delta.length > 0) {
            currentContent += delta
            options.onUpdate(currentContent)
          }
        }
      },
      () => {
        // 流结束
        parser.reset()
        options.onComplete()
      },
      (err: string) => {
        parser.reset()
        Logger.error('AI stream error: %{public}s', err)
        options.onError(err)
      }
    )

    return httpRequest
  }

  // 中止流式请求
  static abortStream(httpRequest: http.HttpRequest): void {
    try {
      httpRequest.off('dataReceive')
      httpRequest.off('dataEnd')
      httpRequest.destroy()
    } catch (err) {
      Logger.warn('Abort stream error: %{public}s', String(err))
    }
  }

  // 非流式 AI 请求（用于 slug 生成等）
  static async sendOnce(
    endpoint: string,
    apiKey: string,
    model: string,
    messages: ChatMessage[]
  ): Promise<string> {
    const messagesArr: Record<string, string>[] = []
    for (let i = 0; i < messages.length; i++) {
      const msg = messages[i]
      const item: Record<string, string> = {
        'role': msg.role,
        'content': msg.content
      }
      messagesArr.push(item)
    }

    const bodyObj: Record<string, Object> = {
      'messages': messagesArr,
      'model': model.length > 0 ? model : 'gpt-3.5-turbo',
      'stream': false,
      'max_tokens': 1000,
      'temperature': 0.3
    }

    const headers: Record<string, string> = {}
    if (apiKey.length > 0) {
      headers['Authorization'] = `Bearer ${apiKey}`
    }

    const response = await HttpClient.postJson(endpoint, JSON.stringify(bodyObj), headers)
    if (!response.success) {
      throw new Error(`AI request failed: ${response.code}`)
    }

    try {
      const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>
      if (parsed['choices'] === undefined || parsed['choices'] === null) {
        return ''
      }
      const choices = parsed['choices'] as Record<string, Object>[]
      if (!Array.isArray(choices) || choices.length === 0) {
        return ''
      }
      const message = choices[0]['message']
      if (message === undefined || message === null || typeof message !== 'object') {
        return ''
      }
      const content = (message as Record<string, string>)['content']
      if (typeof content === 'string') {
        return content.trim()
      }
    } catch (_err) {
      return ''
    }

    return ''
  }

  // 生成 SEO slug
  static async generateSlug(
    title: string,
    endpoint: string,
    apiKey: string,
    model: string
  ): Promise<string> {
    const prompt = `请将以下中文标题转换为SEO友好的英文URL别名(slug)。
要求：
1. 全部小写
2. 单词之间用短横线(-)连接
3. 只包含英文字母、数字和短横线
4. 简洁明了，长度控制在3-8个单词
5. 移除无意义的词
6. 直接输出slug结果，不要任何解释

标题：${title}`

    const messages: ChatMessage[] = []
    const msg = new ChatMessage()
    msg.role = 'user'
    msg.content = prompt
    messages.push(msg)

    // 确保端点格式正确
    let targetEndpoint = endpoint
    if (!targetEndpoint.includes('/chat/completions') && !targetEndpoint.includes('/v1/')) {
      targetEndpoint = targetEndpoint.replace(/\/$/, '') + '/chat/completions'
    }

    let slug = await AIStreamClient.sendOnce(targetEndpoint, apiKey, model, messages)

    // 清理结果
    slug = slug.replace(/^["'`]|["'`]$/g, '')
    slug = slug.replace(/^slug[：:]\s*/i, '')
    slug = slug.replace(/\n.*/g, '')
    slug = slug.toLowerCase()
      .replace(/[^a-z0-9\-\s]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .replace(/^-|-$/g, '')
      .substring(0, 60)

    if (slug.length === 0) {
      slug = `article-${Date.now()}`
    }

    return slug
  }

  // 获取可用模型列表（OpenAI 兼容接口）
  static async fetchModels(endpoint: string, apiKey: string): Promise<string[]> {
    // 从 chat/completions 端点推导 models 端点
    let modelsUrl = endpoint.trim().replace(/\/$/, '')
    if (modelsUrl.includes('/chat/completions')) {
      modelsUrl = modelsUrl.replace('/chat/completions', '/models')
    } else if (modelsUrl.includes('/v1/')) {
      modelsUrl = modelsUrl.substring(0, modelsUrl.indexOf('/v1/') + 3) + '/models'
    } else {
      modelsUrl = modelsUrl + '/v1/models'
    }

    const headers: Record<string, string> = {}
    if (apiKey.length > 0) {
      headers['Authorization'] = `Bearer ${apiKey}`
    }

    const response = await HttpClient.get(modelsUrl, headers)
    if (!response.success) {
      throw new Error(`Failed to fetch models: ${response.code}`)
    }

    try {
      const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>
      if (parsed['data'] === undefined || parsed['data'] === null) {
        return []
      }
      const data = parsed['data'] as Record<string, Object>[]
      const models: string[] = []
      if (Array.isArray(data)) {
        for (let i = 0; i < data.length; i++) {
          const modelId = data[i]['id']
          if (typeof modelId === 'string' && modelId.length > 0) {
            models.push(modelId)
          }
        }
      }
      return models
    } catch (_err) {
      return []
    }
  }
}
