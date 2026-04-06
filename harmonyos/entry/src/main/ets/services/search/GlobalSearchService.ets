// 全局搜索服务 - 跨实体搜索

import { ArticleDao } from '../db/ArticleDao'
import { KeywordDao } from '../db/KeywordDao'
import { TemplateDao } from '../db/TemplateDao'
import { TopicDao } from '../db/TopicDao'
import { Logger } from '../../utils/Logger'
import { Article } from '../../models/Article'
import { Keyword } from '../../models/Keyword'
import { ArticleTemplate } from '../../models/ArticleTemplate'
import { Topic } from '../../models/Topic'

// 搜索结果
export class SearchResult {
  id: string = ''
  type: string = ''  // 'article' | 'keyword' | 'template' | 'topic'
  title: string = ''
  subtitle: string = ''
  path: string = ''
}

// 搜索类型信息
export class SearchTypeInfo {
  label: string = ''
  icon: string = ''
}

// 搜索选项
export class SearchOptions {
  userId: string = ''
  limit: number = 20
}

export class GlobalSearchService {

  // 全局搜索 - 搜索文章、关键词、模板、主题
  static async globalSearch(query: string, options: SearchOptions): Promise<SearchResult[]> {
    const searchTerm = query.toLowerCase().trim()

    if (searchTerm.length === 0) {
      return []
    }

    const results: SearchResult[] = []

    try {
      // 搜索文章
      const articles = await GlobalSearchService.searchArticles(searchTerm, options.userId)
      for (let i = 0; i < articles.length; i++) {
        results.push(articles[i])
      }

      // 搜索关键词
      const keywords = await GlobalSearchService.searchKeywords(searchTerm, options.userId)
      for (let i = 0; i < keywords.length; i++) {
        results.push(keywords[i])
      }

      // 搜索模板
      const templates = await GlobalSearchService.searchTemplates(searchTerm, options.userId)
      for (let i = 0; i < templates.length; i++) {
        results.push(templates[i])
      }

      // 搜索主题
      const topics = await GlobalSearchService.searchTopics(searchTerm, options.userId)
      for (let i = 0; i < topics.length; i++) {
        results.push(topics[i])
      }
    } catch (err) {
      Logger.error('Global search failed: %{public}s', String(err))
    }

    // 限制结果数量
    const finalResults: SearchResult[] = []
    const maxCount = options.limit > 0 ? options.limit : 20
    for (let i = 0; i < results.length && i < maxCount; i++) {
      finalResults.push(results[i])
    }

    return finalResults
  }

  // 搜索文章
  private static async searchArticles(searchTerm: string, userId: string): Promise<SearchResult[]> {
    const results: SearchResult[] = []

    try {
      const articles = await ArticleDao.search(userId, searchTerm)
      for (let i = 0; i < articles.length; i++) {
        const article = articles[i]
        const result = new SearchResult()
        result.id = article.id
        result.type = 'article'
        result.title = article.title
        result.subtitle = article.status === 'published' ? '已发布' : '草稿'
        result.path = `/articles/${article.id}`
        results.push(result)
      }
    } catch (err) {
      Logger.error('Search articles failed: %{public}s', String(err))
    }

    return results
  }

  // 搜索关键词
  private static async searchKeywords(searchTerm: string, userId: string): Promise<SearchResult[]> {
    const results: SearchResult[] = []

    try {
      const keywords = await KeywordDao.findByUserId(userId)
      let count = 0
      for (let i = 0; i < keywords.length && count < 5; i++) {
        const keyword = keywords[i]
        if (keyword.keyword.toLowerCase().includes(searchTerm)) {
          const result = new SearchResult()
          result.id = keyword.id
          result.type = 'keyword'
          result.title = keyword.keyword
          result.subtitle = keyword.groupName.length > 0 ? keyword.groupName : '未分组'
          result.path = '/keywords'
          results.push(result)
          count++
        }
      }
    } catch (err) {
      Logger.error('Search keywords failed: %{public}s', String(err))
    }

    return results
  }

  // 搜索模板
  private static async searchTemplates(searchTerm: string, userId: string): Promise<SearchResult[]> {
    const results: SearchResult[] = []

    try {
      const templates = await TemplateDao.findByUserId(userId)
      let count = 0
      for (let i = 0; i < templates.length && count < 5; i++) {
        const template = templates[i]
        if (template.name.toLowerCase().includes(searchTerm) ||
            template.description.toLowerCase().includes(searchTerm)) {
          const result = new SearchResult()
          result.id = template.id
          result.type = 'template'
          result.title = template.name
          result.subtitle = template.description.length > 0 ?
            template.description.substring(0, 50) : '无描述'
          result.path = '/templates'
          results.push(result)
          count++
        }
      }
    } catch (err) {
      Logger.error('Search templates failed: %{public}s', String(err))
    }

    return results
  }

  // 搜索主题
  private static async searchTopics(searchTerm: string, userId: string): Promise<SearchResult[]> {
    const results: SearchResult[] = []

    try {
      const topics = await TopicDao.findByUserId(userId)
      let count = 0
      for (let i = 0; i < topics.length && count < 5; i++) {
        const topic = topics[i]
        if (topic.title.toLowerCase().includes(searchTerm) ||
            topic.description.toLowerCase().includes(searchTerm) ||
            topic.keywords.toLowerCase().includes(searchTerm)) {
          const result = new SearchResult()
          result.id = topic.id
          result.type = 'topic'
          result.title = topic.title
          result.subtitle = topic.category.length > 0 ? topic.category : '未分类'
          result.path = '/topics'
          results.push(result)
          count++
        }
      }
    } catch (err) {
      Logger.error('Search topics failed: %{public}s', String(err))
    }

    return results
  }

  // 获取搜索类型信息
  static getSearchTypeInfo(type: string): SearchTypeInfo {
    const info = new SearchTypeInfo()

    if (type === 'article') {
      info.label = '文章'
      info.icon = 'FileText'
    } else if (type === 'keyword') {
      info.label = '关键词'
      info.icon = 'Tag'
    } else if (type === 'template') {
      info.label = '模板'
      info.icon = 'Layout'
    } else if (type === 'topic') {
      info.label = '主题'
      info.icon = 'Lightbulb'
    } else {
      info.label = '其他'
      info.icon = 'HelpCircle'
    }

    return info
  }
}
