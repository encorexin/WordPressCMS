// AI 图片生成服务，支持多种图片生成 API
// 从 Web 版本 src/utils/imageGeneration.ts 迁移

import { HttpClient } from '../http/HttpClient'
import { Logger } from '../../utils/Logger'
import { ImageGenerationPromptBuilder } from './ImageGenerationPromptBuilder'
import { ImageGenerationResponseHelper, ImagePollResolution } from './ImageGenerationResponseHelper'

// ============ 数据模型 ============

export class ImageGenerationConfig {
  provider: string = 'openai'
  apiKey: string = ''
  apiEndpoint: string = ''
  model: string = ''
}

export class GeneratedImage {
  url: string = ''
  alt: string = ''
}

export class ImageProviderInfo {
  value: string = ''
  label: string = ''
  description: string = ''
  endpoint: string = ''
  models: string[] = []
}

// ============ 提供者配置 ============

function createProvider(value: string, label: string, desc: string, ep: string, models: string[]): ImageProviderInfo {
  const provider = new ImageProviderInfo()
  provider.value = value
  provider.label = label
  provider.description = desc
  provider.endpoint = ep
  provider.models = models
  return provider
}

export const IMAGE_PROVIDERS: ImageProviderInfo[] = [
  createProvider(
    'openai',
    'OpenAI DALL-E',
    '高质量 AI 生成图片',
    'https://api.openai.com/v1/images/generations',
    ['dall-e-3', 'dall-e-2']
  ),
  createProvider(
    'aliyun',
    '阿里云通义万相',
    '阿里云 AI 图片生成',
    'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis',
    ['wanx-v1', 'wanx-lite']
  ),
  createProvider(
    'zhipu',
    '智谱 CogView',
    '智谱 AI 图片生成',
    'https://open.bigmodel.cn/api/paas/v4/images/generations',
    ['cogview-3-plus', 'cogview-3']
  ),
  createProvider(
    'stability',
    'Stability AI',
    'Stable Diffusion 图片生成',
    'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
    ['stable-diffusion-xl-1024-v1-0']
  ),
  createProvider(
    'baidu',
    '百度文心一格',
    '百度 AI 图片生成 (需要 API_KEY:SECRET_KEY)',
    'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2',
    ['v2']
  ),
  createProvider(
    'siliconflow',
    'SiliconFlow 硅基流动',
    '国内高性价比图片生成，FLUX.1-schnell 免费',
    'https://api.siliconflow.cn/v1/images/generations',
    ['black-forest-labs/FLUX.1-schnell', 'stabilityai/stable-diffusion-3-5-large']
  ),
  createProvider(
    'replicate',
    'Replicate',
    '云端模型平台，支持多种开源模型',
    'https://api.replicate.com/v1/predictions',
    ['stability-ai/stable-diffusion-3', 'black-forest-labs/flux-schnell']
  ),
  createProvider(
    'custom',
    '自定义端点',
    '使用自定义 API 端点 (OpenAI 兼容格式)',
    '',
    []
  )
]

// ============ 图片生成服务 ============

export class ImageGenerationService {
  static async generateImage(
    prompt: string,
    config: ImageGenerationConfig,
    onProgress?: (status: string) => void
  ): Promise<GeneratedImage> {
    if (onProgress !== undefined) {
      onProgress('开始生成图片...')
    }

    try {
      const provider = config.provider
      let result: GeneratedImage

      if (provider === 'openai') {
        if (onProgress !== undefined) {
          onProgress('使用 DALL-E 生成中...')
        }
        result = await ImageGenerationService.generateWithOpenAI(prompt, config)
      } else if (provider === 'aliyun') {
        if (onProgress !== undefined) {
          onProgress('使用通义万相生成中...')
        }
        result = await ImageGenerationService.generateWithAliyun(prompt, config)
      } else if (provider === 'zhipu') {
        if (onProgress !== undefined) {
          onProgress('使用智谱 CogView 生成中...')
        }
        result = await ImageGenerationService.generateWithZhipu(prompt, config)
      } else if (provider === 'stability') {
        if (onProgress !== undefined) {
          onProgress('使用 Stable Diffusion 生成中...')
        }
        result = await ImageGenerationService.generateWithStability(prompt, config)
      } else if (provider === 'baidu') {
        if (onProgress !== undefined) {
          onProgress('使用文心一格生成中...')
        }
        result = await ImageGenerationService.generateWithBaidu(prompt, config)
      } else if (provider === 'siliconflow') {
        if (onProgress !== undefined) {
          onProgress('使用 SiliconFlow 生成中...')
        }
        result = await ImageGenerationService.generateWithSiliconFlow(prompt, config)
      } else if (provider === 'replicate') {
        if (onProgress !== undefined) {
          onProgress('使用 Replicate 生成中...')
        }
        result = await ImageGenerationService.generateWithReplicate(prompt, config)
      } else if (provider === 'custom') {
        if (onProgress !== undefined) {
          onProgress('使用自定义端点生成中...')
        }
        result = await ImageGenerationService.generateWithCustom(prompt, config)
      } else {
        throw new Error('不支持的图片生成服务: ' + provider)
      }

      if (onProgress !== undefined) {
        onProgress('图片生成完成！')
      }
      return result
    } catch (error) {
      if (onProgress !== undefined) {
        onProgress('图片生成失败')
      }
      Logger.error(
        'ImageGenerationService.generateImage failed: %{public}s',
        `provider=${config.provider}, promptLength=${String(prompt.length)}, error=${String(error)}`
      )
      if (error instanceof Error) {
        throw error
      }
      throw new Error('图片生成失败')
    }
  }

  private static async generateWithOpenAI(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.openai.com/v1/images/generations'
    const model = config.model.length > 0 ? config.model : 'dall-e-3'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const body = ImageGenerationPromptBuilder.buildOpenAIBody(prompt, model)

    const response = await HttpClient.postJson(endpoint, body, headers)
    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const imageUrl = ImageGenerationResponseHelper.extractFlexibleImageUrl(response.data, 'generateWithOpenAI')
    if (imageUrl.length === 0) {
      throw new Error('获取图片 URL 失败')
    }

    return ImageGenerationService.buildGeneratedImage(prompt, imageUrl)
  }

  private static async generateWithAliyun(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis'
    const model = config.model.length > 0 ? config.model : 'wanx-v1'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey,
      'X-DashScope-Async': 'enable'
    }
    const body = ImageGenerationPromptBuilder.buildAliyunBody(prompt, model)

    const submitResponse = await HttpClient.postJson(endpoint, body, headers)
    if (!submitResponse.success) {
      throw new Error('提交任务失败: ' + submitResponse.data)
    }

    const taskId = ImageGenerationResponseHelper.extractAliyunTaskId(submitResponse.data)
    if (taskId.length === 0) {
      throw new Error('获取任务 ID 失败')
    }

    const resultEndpoint = 'https://dashscope.aliyuncs.com/api/v1/tasks/' + taskId
    const pollHeaders: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const checkFn = (responseData: string): ImagePollResolution => {
      return ImageGenerationResponseHelper.resolveAliyunPollResult(responseData)
    }

    return ImageGenerationService.pollForResult(resultEndpoint, pollHeaders, prompt, checkFn)
  }

  private static async generateWithZhipu(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://open.bigmodel.cn/api/paas/v4/images/generations'
    const model = config.model.length > 0 ? config.model : 'cogview-3-plus'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const body = ImageGenerationPromptBuilder.buildZhipuBody(prompt, model)

    const response = await HttpClient.postJson(endpoint, body, headers)
    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const imageUrl = ImageGenerationResponseHelper.extractFlexibleImageUrl(response.data, 'generateWithZhipu')
    if (imageUrl.length === 0) {
      throw new Error('获取图片 URL 失败')
    }

    return ImageGenerationService.buildGeneratedImage(prompt, imageUrl)
  }

  private static async generateWithStability(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey,
      'Accept': 'application/json'
    }
    const body = ImageGenerationPromptBuilder.buildStabilityBody(prompt)

    const response = await HttpClient.postJson(endpoint, body, headers)
    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const base64Image = ImageGenerationResponseHelper.extractBase64Image(response.data)
    if (base64Image.length === 0) {
      throw new Error('获取图片数据失败')
    }

    return ImageGenerationService.buildGeneratedImage(prompt, 'data:image/png;base64,' + base64Image)
  }

  private static async generateWithBaidu(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const parts = config.apiKey.split(':')
    if (parts.length !== 2) {
      throw new Error('百度 API 需要格式: API_KEY:SECRET_KEY')
    }
    const apiKey = parts[0]
    const secretKey = parts[1]

    const tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=' +
      apiKey + '&client_secret=' + secretKey
    const tokenResponse = await HttpClient.postJson(tokenUrl, '{}', {})
    if (!tokenResponse.success) {
      throw new Error('获取百度 access_token 失败')
    }

    const accessToken = ImageGenerationResponseHelper.extractAccessToken(tokenResponse.data)
    if (accessToken.length === 0) {
      throw new Error('获取百度 access_token 失败')
    }

    const endpoint = (config.apiEndpoint.length > 0
      ? config.apiEndpoint
      : 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2') + '?access_token=' + accessToken
    const body = ImageGenerationPromptBuilder.buildBaiduCreateBody(prompt)

    const response = await HttpClient.postJson(endpoint, body, {})
    if (!response.success) {
      throw new Error('图片生成请求失败: ' + response.data)
    }

    const taskId = ImageGenerationResponseHelper.extractBaiduTaskId(response.data)
    if (taskId.length === 0) {
      throw new Error('获取任务 ID 失败')
    }

    const queryEndpoint = 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/getImgv2?access_token=' + accessToken
    const queryBody = ImageGenerationPromptBuilder.buildBaiduQueryBody(taskId)
    let attempts = 0
    const maxAttempts = 60
    const intervalMs = 2000

    while (attempts < maxAttempts) {
      await new Promise<void>((resolve: Function) => {
        setTimeout(() => { resolve() }, intervalMs)
      })

      const queryResponse = await HttpClient.postJson(queryEndpoint, queryBody, {
        'Content-Type': 'application/json'
      })

      if (queryResponse.success) {
        const checkResult = ImageGenerationResponseHelper.resolveBaiduPollResult(queryResponse.data)
        if (checkResult.isCompleted) {
          if (checkResult.imageUrl.length > 0) {
            return ImageGenerationService.buildGeneratedImage(prompt, checkResult.imageUrl)
          }
          if (checkResult.errorMessage.length > 0) {
            throw new Error(checkResult.errorMessage)
          }
        }
      }

      attempts++
    }

    throw new Error('图片生成超时')
  }

  private static async generateWithSiliconFlow(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.siliconflow.cn/v1/images/generations'
    const model = config.model.length > 0 ? config.model : 'black-forest-labs/FLUX.1-schnell'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const body = ImageGenerationPromptBuilder.buildSiliconFlowBody(prompt, model)

    const response = await HttpClient.postJson(endpoint, body, headers)
    if (!response.success) {
      throw new Error('SiliconFlow: 请求失败 ' + response.data)
    }

    const imageUrl = ImageGenerationResponseHelper.extractFlexibleImageUrl(response.data, 'generateWithSiliconFlow')
    if (imageUrl.length === 0) {
      throw new Error('SiliconFlow: 未能获取图片 URL')
    }

    return ImageGenerationService.buildGeneratedImage(prompt, imageUrl)
  }

  private static async generateWithReplicate(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.replicate.com/v1/predictions'
    const model = config.model.length > 0 ? config.model : 'stability-ai/stable-diffusion-3'
    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const body = ImageGenerationPromptBuilder.buildReplicateBody(prompt, model)

    const response = await HttpClient.postJson(endpoint, body, headers)
    if (!response.success) {
      throw new Error('Replicate: 请求失败 ' + response.data)
    }

    const pollUrl = ImageGenerationResponseHelper.extractReplicatePollUrl(response.data)
    if (pollUrl.length === 0) {
      throw new Error('Replicate: 获取任务 URL 失败')
    }

    const pollHeaders: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const checkFn = (responseData: string): ImagePollResolution => {
      return ImageGenerationResponseHelper.resolveReplicatePollResult(responseData)
    }

    return ImageGenerationService.pollForResult(pollUrl, pollHeaders, prompt, checkFn)
  }

  private static async generateWithCustom(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    if (config.apiEndpoint.length === 0) {
      throw new Error('自定义端点需要提供 API 端点')
    }

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }
    const model = config.model.length > 0 ? config.model : 'default'
    const body = ImageGenerationPromptBuilder.buildCustomBody(prompt, model)

    const response = await HttpClient.postJson(config.apiEndpoint, body, headers)
    if (!response.success) {
      throw new Error('自定义端点请求失败: ' + response.data)
    }

    const imageUrl = ImageGenerationResponseHelper.extractFlexibleImageUrl(response.data, 'generateWithCustom')
    if (imageUrl.length === 0) {
      throw new Error('无法从响应中获取图片 URL')
    }

    return ImageGenerationService.buildGeneratedImage(prompt, imageUrl)
  }

  private static buildGeneratedImage(prompt: string, imageUrl: string): GeneratedImage {
    const result = new GeneratedImage()
    result.url = imageUrl
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  private static async pollForResult(
    url: string,
    headers: Record<string, string>,
    prompt: string,
    checkFn: (responseData: string) => ImagePollResolution,
    maxAttempts: number = 60,
    intervalMs: number = 2000
  ): Promise<GeneratedImage> {
    let attempts = 0

    while (attempts < maxAttempts) {
      await new Promise<void>((resolve: Function) => {
        setTimeout(() => { resolve() }, intervalMs)
      })

      const response = await HttpClient.get(url, headers)
      if (response.success) {
        const checkResult = checkFn(response.data)
        if (checkResult.isCompleted) {
          if (checkResult.imageUrl.length > 0) {
            return ImageGenerationService.buildGeneratedImage(prompt, checkResult.imageUrl)
          }
          if (checkResult.errorMessage.length > 0) {
            throw new Error(checkResult.errorMessage)
          }
        }
      }

      attempts++
    }

    throw new Error('图片生成超时')
  }

  static generateImagePrompt(keywords: string, title: string): string {
    return ImageGenerationPromptBuilder.generateImagePrompt(keywords, title)
  }

  static insertImageToContent(content: string, imageUrl: string, alt: string): string {
    return ImageGenerationPromptBuilder.insertImageToContent(content, imageUrl, alt)
  }
}
