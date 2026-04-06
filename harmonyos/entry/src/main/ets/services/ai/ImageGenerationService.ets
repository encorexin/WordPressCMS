// AI 图片生成服务 - 支持多种 API (ArkTS 版本)
// 从 Web 版本 src/utils/imageGeneration.ts 移植

import { HttpClient } from '../http/HttpClient'
import { Logger } from '../../utils/Logger'

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
  let p = new ImageProviderInfo()
  p.value = value
  p.label = label
  p.description = desc
  p.endpoint = ep
  p.models = models
  return p
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

  // 主入口方法
  static async generateImage(
    prompt: string,
    config: ImageGenerationConfig,
    onProgress?: (status: string) => void
  ): Promise<GeneratedImage> {
    if (onProgress !== undefined) {
      onProgress('开始生成图片...')
    }

    try {
      let result: GeneratedImage | null = null
      const provider: string = config.provider

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
      if (error instanceof Error) {
        throw error
      }
      throw new Error('图片生成失败')
    }
  }

  // ============ 各提供者实现 ============

  // OpenAI DALL-E 生成
  private static async generateWithOpenAI(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.openai.com/v1/images/generations'
    const model: string = config.model.length > 0 ? config.model : 'dall-e-3'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
      'response_format': 'url'
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, headers)

    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    let imageUrl: string = ''
    if (parsed['data'] !== undefined) {
      const dataArr: Array<Object> = parsed['data'] as Array<Object>
      if (dataArr.length > 0) {
        const firstItem: Record<string, Object> = dataArr[0] as Record<string, Object>
        if (firstItem['url'] !== undefined && typeof firstItem['url'] === 'string') {
          imageUrl = firstItem['url'] as string
        }
      }
    }

    if (imageUrl.length === 0) {
      throw new Error('获取图片URL失败')
    }

    let result: GeneratedImage = new GeneratedImage()
    result.url = imageUrl
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  // 阿里云通义万相生成 (异步轮询)
  private static async generateWithAliyun(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis'
    const model: string = config.model.length > 0 ? config.model : 'wanx-v1'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey,
      'X-DashScope-Async': 'enable'
    }

    const inputObj: Record<string, Object> = {
      'prompt': prompt
    }
    const paramsObj: Record<string, Object> = {
      'size': '1024*1024',
      'n': 1
    }
    const bodyObj: Record<string, Object> = {
      'model': model,
      'input': inputObj,
      'parameters': paramsObj
    }
    const body: string = JSON.stringify(bodyObj)

    const submitResponse = await HttpClient.postJson(endpoint, body, headers)

    if (!submitResponse.success) {
      throw new Error('提交任务失败: ' + submitResponse.data)
    }

    const submitData: Record<string, Object> = JSON.parse(submitResponse.data) as Record<string, Object>

    let taskId: string = ''
    if (submitData['output'] !== undefined) {
      const output: Record<string, Object> = submitData['output'] as Record<string, Object>
      if (output['task_id'] !== undefined && typeof output['task_id'] === 'string') {
        taskId = output['task_id'] as string
      }
    }

    if (taskId.length === 0) {
      throw new Error('获取任务ID失败')
    }

    // 轮询获取结果
    const resultEndpoint: string = 'https://dashscope.aliyuncs.com/api/v1/tasks/' + taskId
    const pollHeaders: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const checkFn: (data: Record<string, Object>) => GeneratedImage | null | string = (data: Record<string, Object>): GeneratedImage | null | string => {
      if (data['output'] !== undefined) {
        const output: Record<string, Object> = data['output'] as Record<string, Object>
        const status: Object = output['task_status']
        if (status === 'SUCCEEDED') {
          const results: Array<Object> = output['results'] as Array<Object>
          if (results.length > 0) {
            const firstResult: Record<string, Object> = results[0] as Record<string, Object>
            if (firstResult['url'] !== undefined && typeof firstResult['url'] === 'string') {
              let img: GeneratedImage = new GeneratedImage()
              img.url = firstResult['url'] as string
              img.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
              return img
            }
          }
          return '获取图片URL失败'
        } else if (status === 'FAILED') {
          let errorMsg: string = '图片生成失败'
          if (output['message'] !== undefined && typeof output['message'] === 'string') {
            errorMsg = output['message'] as string
          }
          return errorMsg
        }
      }
      return null
    }

    return ImageGenerationService.pollForResult(resultEndpoint, pollHeaders, checkFn)
  }

  // 智谱 AI CogView 生成
  private static async generateWithZhipu(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://open.bigmodel.cn/api/paas/v4/images/generations'
    const model: string = config.model.length > 0 ? config.model : 'cogview-3-plus'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'size': '1024x1024'
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, headers)

    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    let imageUrl: string = ''
    if (parsed['data'] !== undefined) {
      const dataArr: Array<Object> = parsed['data'] as Array<Object>
      if (dataArr.length > 0) {
        const firstItem: Record<string, Object> = dataArr[0] as Record<string, Object>
        if (firstItem['url'] !== undefined && typeof firstItem['url'] === 'string') {
          imageUrl = firstItem['url'] as string
        }
      }
    }

    if (imageUrl.length === 0) {
      throw new Error('获取图片URL失败')
    }

    let result: GeneratedImage = new GeneratedImage()
    result.url = imageUrl
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  // Stability AI 生成 (返回 base64)
  private static async generateWithStability(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey,
      'Accept': 'application/json'
    }

    const textPrompt: Record<string, Object> = {
      'text': prompt,
      'weight': 1
    }
    const bodyObj: Record<string, Object> = {
      'text_prompts': [textPrompt],
      'cfg_scale': 7,
      'height': 1024,
      'width': 1024,
      'samples': 1,
      'steps': 30
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, headers)

    if (!response.success) {
      throw new Error('图片生成失败: ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    let base64Image: string = ''
    if (parsed['artifacts'] !== undefined) {
      const artifacts: Array<Object> = parsed['artifacts'] as Array<Object>
      if (artifacts.length > 0) {
        const firstArtifact: Record<string, Object> = artifacts[0] as Record<string, Object>
        if (firstArtifact['base64'] !== undefined && typeof firstArtifact['base64'] === 'string') {
          base64Image = firstArtifact['base64'] as string
        }
      }
    }

    if (base64Image.length === 0) {
      throw new Error('获取图片数据失败')
    }

    let result: GeneratedImage = new GeneratedImage()
    result.url = 'data:image/png;base64,' + base64Image
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  // 百度文心一格生成 (需要获取 access_token 并轮询)
  private static async generateWithBaidu(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    // 解析 apiKey 格式 "API_KEY:SECRET_KEY"
    const parts: string[] = config.apiKey.split(':')
    if (parts.length !== 2) {
      throw new Error('百度 API 需要格式: API_KEY:SECRET_KEY')
    }
    const apiKey: string = parts[0]
    const secretKey: string = parts[1]

    // 获取 access_token
    const tokenUrl: string = 'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=' + apiKey + '&client_secret=' + secretKey
    const tokenResponse = await HttpClient.postJson(tokenUrl, '{}', {})

    if (!tokenResponse.success) {
      throw new Error('获取百度 access_token 失败')
    }

    const tokenData: Record<string, Object> = JSON.parse(tokenResponse.data) as Record<string, Object>
    let accessToken: string = ''
    if (tokenData['access_token'] !== undefined && typeof tokenData['access_token'] === 'string') {
      accessToken = tokenData['access_token'] as string
    }

    if (accessToken.length === 0) {
      throw new Error('获取百度 access_token 失败')
    }

    // 提交生成任务
    const endpoint: string = (config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2') + '?access_token=' + accessToken

    const bodyObj: Record<string, Object> = {
      'prompt': prompt,
      'width': 1024,
      'height': 1024,
      'image_num': 1
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, {})

    if (!response.success) {
      throw new Error('图片生成请求失败: ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    if (parsed['error_code'] !== undefined) {
      let errorMsg: string = '图片生成失败'
      if (parsed['error_msg'] !== undefined && typeof parsed['error_msg'] === 'string') {
        errorMsg = parsed['error_msg'] as string
      }
      throw new Error(errorMsg)
    }

    let taskId: string = ''
    if (parsed['data'] !== undefined) {
      const data: Record<string, Object> = parsed['data'] as Record<string, Object>
      if (data['task_id'] !== undefined && typeof data['task_id'] === 'string') {
        taskId = data['task_id'] as string
      }
    }

    if (taskId.length === 0) {
      throw new Error('获取任务ID失败')
    }

    // 轮询查询结果
    const queryEndpoint: string = 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/getImgv2?access_token=' + accessToken

    const checkFn: (data: Record<string, Object>) => GeneratedImage | null | string = (data: Record<string, Object>): GeneratedImage | null | string => {
      if (data['data'] !== undefined) {
        const taskData: Record<string, Object> = data['data'] as Record<string, Object>
        const status: Object = taskData['task_status']
        if (status === 'SUCCESS') {
          const resultList: Array<Object> = taskData['sub_task_result_list'] as Array<Object>
          if (resultList.length > 0) {
            const firstResult: Record<string, Object> = resultList[0] as Record<string, Object>
            const finalImageList: Array<Object> = firstResult['final_image_list'] as Array<Object>
            if (finalImageList.length > 0) {
              const firstImage: Record<string, Object> = finalImageList[0] as Record<string, Object>
              if (firstImage['img_url'] !== undefined && typeof firstImage['img_url'] === 'string') {
                let img: GeneratedImage = new GeneratedImage()
                img.url = firstImage['img_url'] as string
                img.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
                return img
              }
            }
          }
          return '获取图片URL失败'
        } else if (status === 'FAILED') {
          return '图片生成失败'
        }
      }
      return null
    }

    const queryBody: Record<string, Object> = {
      'task_id': taskId
    }
    const queryBodyStr: string = JSON.stringify(queryBody)

    // 使用自定义轮询，因为百度需要 POST 请求
    let attempts: number = 0
    const maxAttempts: number = 60
    const intervalMs: number = 2000

    while (attempts < maxAttempts) {
      await new Promise<void>((resolve: Function) => {
        setTimeout(() => { resolve() }, intervalMs)
      })

      const queryResponse = await HttpClient.postJson(queryEndpoint, queryBodyStr, {
        'Content-Type': 'application/json'
      })

      if (queryResponse.success) {
        const queryData: Record<string, Object> = JSON.parse(queryResponse.data) as Record<string, Object>
        const checkResult: GeneratedImage | null | string = checkFn(queryData)

        if (checkResult instanceof GeneratedImage) {
          return checkResult
        } else if (typeof checkResult === 'string') {
          throw new Error(checkResult)
        }
      }

      attempts++
    }

    throw new Error('图片生成超时')
  }

  // SiliconFlow 生成 (OpenAI 兼容格式)
  private static async generateWithSiliconFlow(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.siliconflow.cn/v1/images/generations'
    const model: string = config.model.length > 0 ? config.model : 'black-forest-labs/FLUX.1-schnell'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'image_size': '1024x1024',
      'batch_size': 1,
      'num_inference_steps': 20
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, headers)

    if (!response.success) {
      throw new Error('SiliconFlow: 请求失败 ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    let imageUrl: string = ''

    // 尝试 images[0].url 格式
    if (parsed['images'] !== undefined) {
      const images: Array<Object> = parsed['images'] as Array<Object>
      if (images.length > 0) {
        const firstImage: Record<string, Object> = images[0] as Record<string, Object>
        if (firstImage['url'] !== undefined && typeof firstImage['url'] === 'string') {
          imageUrl = firstImage['url'] as string
        }
      }
    }

    // 尝试 data[0].url 格式
    if (imageUrl.length === 0 && parsed['data'] !== undefined) {
      const dataArr: Array<Object> = parsed['data'] as Array<Object>
      if (dataArr.length > 0) {
        const firstItem: Record<string, Object> = dataArr[0] as Record<string, Object>
        if (firstItem['url'] !== undefined && typeof firstItem['url'] === 'string') {
          imageUrl = firstItem['url'] as string
        }
      }
    }

    if (imageUrl.length === 0) {
      throw new Error('SiliconFlow: 未能获取图片 URL')
    }

    let result: GeneratedImage = new GeneratedImage()
    result.url = imageUrl
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  // Replicate 生成 (异步轮询)
  private static async generateWithReplicate(
    prompt: string,
    config: ImageGenerationConfig
  ): Promise<GeneratedImage> {
    const endpoint: string = config.apiEndpoint.length > 0 ? config.apiEndpoint : 'https://api.replicate.com/v1/predictions'
    const model: string = config.model.length > 0 ? config.model : 'stability-ai/stable-diffusion-3'

    const headers: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const inputObj: Record<string, Object> = {
      'prompt': prompt,
      'width': 1024,
      'height': 1024
    }
    const bodyObj: Record<string, Object> = {
      'version': model,
      'input': inputObj
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(endpoint, body, headers)

    if (!response.success) {
      throw new Error('Replicate: 请求失败 ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    // 获取轮询 URL
    let pollUrl: string = ''
    if (parsed['urls'] !== undefined) {
      const urls: Record<string, Object> = parsed['urls'] as Record<string, Object>
      if (urls['get'] !== undefined && typeof urls['get'] === 'string') {
        pollUrl = urls['get'] as string
      }
    }

    if (pollUrl.length === 0) {
      throw new Error('Replicate: 获取任务URL失败')
    }

    // 轮询获取结果
    const pollHeaders: Record<string, string> = {
      'Authorization': 'Bearer ' + config.apiKey
    }

    const checkFn: (data: Record<string, Object>) => GeneratedImage | null | string = (data: Record<string, Object>): GeneratedImage | null | string => {
      const status: Object = data['status']
      if (status === 'succeeded') {
        const output: Object = data['output']
        let imageUrl: string = ''
        if (output instanceof Array) {
          const outputArr: Array<Object> = output as Array<Object>
          if (outputArr.length > 0) {
            imageUrl = outputArr[0] as string
          }
        } else if (typeof output === 'string') {
          imageUrl = output
        }

        if (imageUrl.length > 0) {
          let img: GeneratedImage = new GeneratedImage()
          img.url = imageUrl
          img.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
          return img
        }
        return 'Replicate: 获取图片URL失败'
      } else if (status === 'failed') {
        let errorMsg: string = '图片生成失败'
        if (data['error'] !== undefined && typeof data['error'] === 'string') {
          errorMsg = data['error'] as string
        }
        return errorMsg
      }
      return null
    }

    return ImageGenerationService.pollForResult(pollUrl, pollHeaders, checkFn)
  }

  // 自定义端点生成 (OpenAI 兼容格式)
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

    const bodyObj: Record<string, Object> = {
      'model': config.model.length > 0 ? config.model : 'default',
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024'
    }
    const body: string = JSON.stringify(bodyObj)

    const response = await HttpClient.postJson(config.apiEndpoint, body, headers)

    if (!response.success) {
      throw new Error('自定义端点请求失败: ' + response.data)
    }

    const parsed: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>

    // 尝试多种响应格式
    let imageUrl: string = ''

    // data[0].url
    if (parsed['data'] !== undefined) {
      const dataArr: Array<Object> = parsed['data'] as Array<Object>
      if (dataArr.length > 0) {
        const firstItem: Record<string, Object> = dataArr[0] as Record<string, Object>
        if (firstItem['url'] !== undefined && typeof firstItem['url'] === 'string') {
          imageUrl = firstItem['url'] as string
        }
      }
    }

    // images[0].url
    if (imageUrl.length === 0 && parsed['images'] !== undefined) {
      const images: Array<Object> = parsed['images'] as Array<Object>
      if (images.length > 0) {
        const firstImage: Record<string, Object> = images[0] as Record<string, Object>
        if (firstImage['url'] !== undefined && typeof firstImage['url'] === 'string') {
          imageUrl = firstImage['url'] as string
        }
      }
    }

    // output[0]
    if (imageUrl.length === 0 && parsed['output'] !== undefined) {
      const output: Object = parsed['output']
      if (output instanceof Array) {
        const outputArr: Array<Object> = output as Array<Object>
        if (outputArr.length > 0) {
          imageUrl = outputArr[0] as string
        }
      }
    }

    // url
    if (imageUrl.length === 0 && parsed['url'] !== undefined && typeof parsed['url'] === 'string') {
      imageUrl = parsed['url'] as string
    }

    // image_url
    if (imageUrl.length === 0 && parsed['image_url'] !== undefined && typeof parsed['image_url'] === 'string') {
      imageUrl = parsed['image_url'] as string
    }

    if (imageUrl.length === 0) {
      throw new Error('无法从响应中获取图片 URL')
    }

    let result: GeneratedImage = new GeneratedImage()
    result.url = imageUrl
    result.alt = prompt.length > 100 ? prompt.substring(0, 100) : prompt
    return result
  }

  // ============ 辅助方法 ============

  // 轮询结果通用方法
  private static async pollForResult(
    url: string,
    headers: Record<string, string>,
    checkFn: (data: Record<string, Object>) => GeneratedImage | null | string,
    maxAttempts: number = 60,
    intervalMs: number = 2000
  ): Promise<GeneratedImage> {
    let attempts: number = 0

    while (attempts < maxAttempts) {
      await new Promise<void>((resolve: Function) => {
        setTimeout(() => { resolve() }, intervalMs)
      })

      const response = await HttpClient.get(url, headers)

      if (response.success) {
        const data: Record<string, Object> = JSON.parse(response.data) as Record<string, Object>
        const checkResult: GeneratedImage | null | string = checkFn(data)

        if (checkResult instanceof GeneratedImage) {
          return checkResult
        } else if (typeof checkResult === 'string') {
          throw new Error(checkResult)
        }
      }

      attempts++
    }

    throw new Error('图片生成超时')
  }

  // 生成图片提示词
  static generateImagePrompt(keywords: string, title: string): string {
    return 'A professional, high-quality illustration for an article about "' + title + '". Keywords: ' + keywords + '. Style: modern, clean, professional, suitable for blog post header image. No text or watermarks.'
  }

  // 将图片插入到 Markdown 内容中
  static insertImageToContent(content: string, imageUrl: string, alt: string): string {
    const imageMarkdown: string = '![' + alt + '](' + imageUrl + ')\n\n'
    return imageMarkdown + content
  }
}
