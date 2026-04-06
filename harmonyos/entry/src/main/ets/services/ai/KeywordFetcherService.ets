// AI 关键词获取服务

import { AISettingsDao } from '../db/AISettingsDao'
import { AIStreamClient, ChatMessage } from '../http/AIStreamClient'
import { HttpClient } from '../http/HttpClient'
import { Logger } from '../../utils/Logger'

export class FetchKeywordsResult {
  success: boolean = false
  keywords: string[] = []
  error: string = ''
}

export class KeywordFetcherService {

  // 从 AI 获取关键词
  static async fetchKeywordsFromAI(
    userId: string,
    topic: string,
    count: number = 20
  ): Promise<FetchKeywordsResult> {
    const result = new FetchKeywordsResult()

    try {
      const settings = await AISettingsDao.findDefault(userId)

      if (settings === null || settings.apiKey.length === 0 || settings.apiEndpoint.length === 0) {
        result.success = false
        result.error = '请先在 AI 设置中配置 API'
        return result
      }

      const prompt = `请为主题"${topic}"生成 ${count} 个相关的关键词或长尾关键词。

要求：
1. 关键词应该与主题高度相关
2. 包含一些热门搜索词
3. 包含一些长尾关键词
4. 适合用于文章创作和SEO优化

请直接输出关键词列表，每行一个，不要编号，不要其他解释。`

      const messages: ChatMessage[] = []

      const systemMsg = new ChatMessage()
      systemMsg.role = 'system'
      systemMsg.content = '你是一个SEO专家，擅长生成高质量的关键词。'
      messages.push(systemMsg)

      const userMsg = new ChatMessage()
      userMsg.role = 'user'
      userMsg.content = prompt
      messages.push(userMsg)

      const response = await AIStreamClient.sendOnce(
        settings.apiEndpoint,
        settings.apiKey,
        settings.model,
        messages
      )

      if (response.length === 0) {
        result.success = false
        result.error = 'AI 返回空响应'
        return result
      }

      // 解析关键词：按行分割，清理格式
      const keywords: string[] = []
      const lines = response.split('\n')

      for (let i = 0; i < lines.length; i++) {
        let line = lines[i].trim()

        // 跳过空行
        if (line.length === 0) {
          continue
        }

        // 移除行首的数字、横线、星号、点号等标记
        // 使用简单的字符检查而不是正则
        let startIndex = 0
        while (startIndex < line.length) {
          const char = line.charAt(startIndex)
          // 如果是数字、横线、星号、点号或空格，继续
          if ((char >= '0' && char <= '9') || char === '-' || char === '*' || char === '.' || char === ' ') {
            startIndex++
          } else {
            break
          }
        }
        line = line.substring(startIndex).trim()

        // 过滤无效行
        if (line.length === 0) {
          continue
        }

        // 过滤过长的行（可能是句子而不是关键词）
        if (line.length >= 50) {
          continue
        }

        keywords.push(line)
      }

      // 去重
      const uniqueKeywords: string[] = []
      for (let i = 0; i < keywords.length; i++) {
        let isDuplicate = false
        for (let j = 0; j < uniqueKeywords.length; j++) {
          if (keywords[i] === uniqueKeywords[j]) {
            isDuplicate = true
            break
          }
        }
        if (!isDuplicate) {
          uniqueKeywords.push(keywords[i])
        }
      }

      result.success = true
      result.keywords = uniqueKeywords
      return result

    } catch (err) {
      Logger.error('获取关键词失败: %{public}s', String(err))
      result.success = false
      result.error = '获取关键词失败: ' + String(err)
      return result
    }
  }

  // 从 Google Trends 获取关键词建议
  static async fetchKeywordsFromTrends(topic: string): Promise<FetchKeywordsResult> {
    const result = new FetchKeywordsResult()

    try {
      const encodedTopic = encodeURIComponent(topic)
      const googleUrl = `https://suggestqueries.google.com/complete/search?client=firefox&q=${encodedTopic}`
      const proxyUrl = `https://api.allorigins.win/raw?url=${encodeURIComponent(googleUrl)}`

      const response = await HttpClient.get(proxyUrl)

      if (!response.success) {
        result.success = false
        result.error = '网络请求失败'
        return result
      }

      try {
        const parsed = JSON.parse(response.data) as Object[]

        if (Array.isArray(parsed) && parsed.length > 1) {
          const suggestionsObj = parsed[1]
          if (Array.isArray(suggestionsObj)) {
            const suggestions: string[] = []
            // 最多取 10 个
            const maxCount = suggestionsObj.length < 10 ? suggestionsObj.length : 10
            for (let i = 0; i < maxCount; i++) {
              const item = suggestionsObj[i]
              if (typeof item === 'string') {
                suggestions.push(item)
              }
            }

            result.success = true
            result.keywords = suggestions
            return result
          }
        }

        result.success = false
        result.error = '未获取到相关建议'
        return result

      } catch (parseErr) {
        Logger.error('解析 Trends 响应失败: %{public}s', String(parseErr))
        result.success = false
        result.error = '解析响应失败'
        return result
      }

    } catch (err) {
      Logger.error('获取搜索建议失败: %{public}s', String(err))
      result.success = false
      result.error = '获取搜索建议失败'
      return result
    }
  }
}
