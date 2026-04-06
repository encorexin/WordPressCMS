// WordPress REST API 客户端

import { HttpClient, RequestOptions } from './HttpClient'
import { WordPressSite } from '../../models/WordPressSite'
import { Logger } from '../../utils/Logger'
import http from '@ohos.net.http'

// WordPress 分类
export class WordPressCategory {
  id: number = 0
  name: string = ''
  slug: string = ''
  parent: number = 0
  count: number = 0
}

// API 通用结果
export class WPResult {
  success: boolean = false
  message: string = ''
}

// 发布结果（含文章 ID）
export class WPPublishResult extends WPResult {
  postId: string = ''
}

// 分类列表结果
export class WPCategoryResult extends WPResult {
  categories: WordPressCategory[] = []
}

// 标签
export class WordPressTag {
  id: number = 0
  name: string = ''
  slug: string = ''
}

// 标签列表结果
export class WPTagResult extends WPResult {
  tags: WordPressTag[] = []
}

// 创建标签结果
export class WPCreateTagResult extends WPResult {
  tagId: number = 0
  tagName: string = ''
}

// 媒体上传结果
export class WPMediaResult extends WPResult {
  mediaId: number = 0
  sourceUrl: string = ''
}

export class WordPressApi {

  private static getApiUrl(siteUrl: string): string {
    const cleanUrl = siteUrl.replace(/\/$/, '')
    return `${cleanUrl}/wp-json/wp/v2`
  }

  private static getAuthHeaders(site: WordPressSite): Record<string, string> {
    return {
      'Authorization': HttpClient.createBasicAuth(site.username, site.appPassword),
      'Content-Type': 'application/json'
    }
  }

  // 测试站点连接
  static async testConnection(site: WordPressSite): Promise<WPResult> {
    const result = new WPResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/users/me`
      const response = await HttpClient.get(url, WordPressApi.getAuthHeaders(site))

      if (response.success) {
        result.success = true
        result.message = '连接成功'
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP testConnection failed: %{public}s', String(err))
      result.message = '连接失败'
    }
    return result
  }

  // 获取分类列表
  static async getCategories(site: WordPressSite): Promise<WPCategoryResult> {
    const result = new WPCategoryResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/categories?per_page=100`
      const response = await HttpClient.get(url, WordPressApi.getAuthHeaders(site))

      if (response.success) {
        try {
          const parsed: Record<string, Object>[] = JSON.parse(response.data) as Record<string, Object>[]
          const categories: WordPressCategory[] = []
          if (Array.isArray(parsed)) {
            for (let i = 0; i < parsed.length; i++) {
              const cat = new WordPressCategory()
              const item = parsed[i]
              if (typeof item['id'] === 'number') {
                cat.id = item['id'] as number
              }
              if (typeof item['name'] === 'string') {
                cat.name = item['name'] as string
              }
              if (typeof item['slug'] === 'string') {
                cat.slug = item['slug'] as string
              }
              if (typeof item['parent'] === 'number') {
                cat.parent = item['parent'] as number
              }
              if (typeof item['count'] === 'number') {
                cat.count = item['count'] as number
              }
              categories.push(cat)
            }
          }
          result.categories = categories
          result.success = true
          result.message = '获取成功'
        } catch (_err) {
          result.message = '解析分类数据失败'
        }
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP getCategories failed: %{public}s', String(err))
      result.message = '获取分类失败'
    }
    return result
  }

  // 发布文章
  static async publishPost(
    site: WordPressSite,
    title: string,
    content: string,
    categories?: number[],
    slug?: string
  ): Promise<WPPublishResult> {
    const result = new WPPublishResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/posts`
      const postData: Record<string, Object> = {
        'title': title,
        'content': content,
        'status': 'publish'
      }
      if (categories && categories.length > 0) {
        postData['categories'] = categories
      }
      if (slug && slug.length > 0) {
        postData['slug'] = slug
      }

      const response = await HttpClient.postJson(url, JSON.stringify(postData), WordPressApi.getAuthHeaders(site))

      if (response.success) {
        try {
          const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>
          result.success = true
          if (parsed['id'] !== undefined && parsed['id'] !== null) {
            result.postId = String(parsed['id'])
          }
          result.message = '发布成功'
        } catch (_err) {
          result.message = '解析发布响应失败'
        }
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP publishPost failed: %{public}s', String(err))
      result.message = '发布失败'
    }
    return result
  }

  // 更新文章
  static async updatePost(
    site: WordPressSite,
    postId: string,
    title: string,
    content: string,
    categories?: number[],
    slug?: string
  ): Promise<WPResult> {
    const result = new WPResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/posts/${postId}`
      const postData: Record<string, Object> = {
        'title': title,
        'content': content
      }
      if (categories && categories.length > 0) {
        postData['categories'] = categories
      }
      if (slug && slug.length > 0) {
        postData['slug'] = slug
      }

      const response = await HttpClient.postJson(url, JSON.stringify(postData), WordPressApi.getAuthHeaders(site))

      if (response.success) {
        result.success = true
        result.message = '更新成功'
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP updatePost failed: %{public}s', String(err))
      result.message = '更新失败'
    }
    return result
  }

  // 删除文章
  static async deletePost(site: WordPressSite, postId: string): Promise<WPResult> {
    const result = new WPResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/posts/${postId}`
      const options = new RequestOptions()
      options.method = http.RequestMethod.DELETE
      options.headers = WordPressApi.getAuthHeaders(site)
      const response = await HttpClient.request(url, options)

      if (response.success) {
        result.success = true
        result.message = '删除成功'
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP deletePost failed: %{public}s', String(err))
      result.message = '删除失败'
    }
    return result
  }

  // 获取标签列表
  static async getTags(site: WordPressSite): Promise<WPTagResult> {
    const result = new WPTagResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/tags?per_page=100`
      const response = await HttpClient.get(url, WordPressApi.getAuthHeaders(site))

      if (response.success) {
        try {
          const parsed: Record<string, Object>[] = JSON.parse(response.data) as Record<string, Object>[]
          const tags: WordPressTag[] = []
          if (Array.isArray(parsed)) {
            for (let i = 0; i < parsed.length; i++) {
              const tag = new WordPressTag()
              const item = parsed[i]
              if (typeof item['id'] === 'number') {
                tag.id = item['id'] as number
              }
              if (typeof item['name'] === 'string') {
                tag.name = item['name'] as string
              }
              if (typeof item['slug'] === 'string') {
                tag.slug = item['slug'] as string
              }
              tags.push(tag)
            }
          }
          result.tags = tags
          result.success = true
          result.message = '获取成功'
        } catch (_err) {
          result.message = '解析标签数据失败'
        }
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP getTags failed: %{public}s', String(err))
      result.message = '获取标签失败'
    }
    return result
  }

  // 创建标签
  static async createTag(site: WordPressSite, name: string): Promise<WPCreateTagResult> {
    const result = new WPCreateTagResult()
    try {
      const url = `${WordPressApi.getApiUrl(site.siteUrl)}/tags`
      const postData: Record<string, Object> = {
        'name': name
      }

      const response = await HttpClient.postJson(url, JSON.stringify(postData), WordPressApi.getAuthHeaders(site))

      if (response.success) {
        try {
          const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>
          result.success = true
          if (typeof parsed['id'] === 'number') {
            result.tagId = parsed['id'] as number
          }
          if (typeof parsed['name'] === 'string') {
            result.tagName = parsed['name'] as string
          }
          result.message = '创建成功'
        } catch (_err) {
          result.message = '解析创建响应失败'
        }
      } else {
        result.message = WordPressApi.extractErrorMessage(response.data, response.code)
      }
    } catch (err) {
      Logger.error('WP createTag failed: %{public}s', String(err))
      result.message = '创建失败'
    }
    return result
  }

  // 上传媒体文件
  static async uploadMedia(site: WordPressSite, filePath: string, fileName: string,
    mimeType: string): Promise<WPMediaResult> {
    const result = new WPMediaResult()
    // TODO: 实现多部分上传功能 - 将在第四阶段完成
    result.message = '媒体上传功能将在后续版本中支持'
    return result
  }

  // 从响应体提取错误信息
  private static extractErrorMessage(responseData: string, code: number): string {
    try {
      const parsed: Record<string, Object> = JSON.parse(responseData) as Record<string, Object>
      if (typeof parsed['message'] === 'string' && (parsed['message'] as string).length > 0) {
        return parsed['message'] as string
      }
    } catch (_e) {
      // ignore
    }
    return `请求失败: ${code}`
  }
}
