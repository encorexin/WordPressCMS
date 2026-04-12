// 图片生成服务响应解析与轮询结果辅助方法

import { Logger } from '../../utils/Logger'

export interface ImageUrlItemPayload {
  url?: string
}

interface ImageBase64ArtifactPayload {
  base64?: string
}

interface ImageOutputPayload {
  url?: string
}

interface FlexibleImagePayload {
  data?: ImageUrlItemPayload[]
  images?: ImageUrlItemPayload[]
  output?: string[] | string | ImageOutputPayload
  url?: string
  image_url?: string
}

interface AliyunOutputPayload {
  task_id?: string
  task_status?: string
  results?: ImageUrlItemPayload[]
  message?: string
}

interface AliyunResponsePayload {
  output?: AliyunOutputPayload
}

interface StabilityResponsePayload {
  artifacts?: ImageBase64ArtifactPayload[]
}

interface BaiduTokenResponsePayload {
  access_token?: string
}

interface BaiduTaskDataPayload {
  task_id?: string
}

interface BaiduCreateResponsePayload {
  error_code?: number | string
  error_msg?: string
  data?: BaiduTaskDataPayload
}

interface BaiduFinalImagePayload {
  img_url?: string
}

interface BaiduSubTaskResultPayload {
  final_image_list?: BaiduFinalImagePayload[]
}

interface BaiduPollDataPayload {
  task_status?: string
  sub_task_result_list?: BaiduSubTaskResultPayload[]
}

interface BaiduPollResponsePayload {
  data?: BaiduPollDataPayload
}

interface ReplicateUrlsPayload {
  get?: string
}

interface ReplicatePredictionResponsePayload {
  urls?: ReplicateUrlsPayload
  status?: string
  output?: string[] | string
  error?: string
}

export class ImagePollResolution {
  isCompleted: boolean = false
  imageUrl: string = ''
  errorMessage: string = ''
}

export class ImageGenerationResponseHelper {
  static parseJsonPayload<T>(responseData: string, context: string): T {
    try {
      return JSON.parse(responseData) as T
    } catch (parseErr) {
      Logger.warn(`ImageGenerationService.${context} parse failed: %{public}s`, String(parseErr))
      throw new Error(`${context} 响应解析失败`)
    }
  }

  static tryParseJsonPayload<T>(responseData: string, context: string): T | null {
    try {
      return JSON.parse(responseData) as T
    } catch (parseErr) {
      Logger.warn(`ImageGenerationService.${context} parse failed: %{public}s`, String(parseErr))
      return null
    }
  }

  static extractFlexibleImageUrl(responseData: string, context: string): string {
    const payload = ImageGenerationResponseHelper.parseJsonPayload<FlexibleImagePayload>(responseData, context)

    let imageUrl = ImageGenerationResponseHelper.extractFirstUrl(payload.data)
    if (imageUrl.length === 0) {
      imageUrl = ImageGenerationResponseHelper.extractFirstUrl(payload.images)
    }
    if (imageUrl.length === 0 && Array.isArray(payload.output) && payload.output.length > 0) {
      const firstOutput = payload.output[0]
      if (typeof firstOutput === 'string') {
        imageUrl = firstOutput
      }
    }
    if (imageUrl.length === 0 && typeof payload.output === 'string') {
      imageUrl = payload.output
    }
    const outputPayload = payload.output
    if (imageUrl.length === 0 && outputPayload !== undefined && !Array.isArray(outputPayload) &&
      typeof outputPayload !== 'string' && typeof outputPayload.url === 'string') {
      imageUrl = outputPayload.url
    }
    if (imageUrl.length === 0 && typeof payload.url === 'string') {
      imageUrl = payload.url
    }
    if (imageUrl.length === 0 && typeof payload.image_url === 'string') {
      imageUrl = payload.image_url
    }
    return imageUrl
  }

  static extractAliyunTaskId(responseData: string): string {
    const parsed = ImageGenerationResponseHelper.parseJsonPayload<AliyunResponsePayload>(responseData, 'extractAliyunTaskId')
    return typeof parsed.output?.task_id === 'string' ? parsed.output.task_id : ''
  }

  static resolveAliyunPollResult(responseData: string): ImagePollResolution {
    const parsed = ImageGenerationResponseHelper.tryParseJsonPayload<AliyunResponsePayload>(
      responseData,
      'resolveAliyunPollResult'
    )
    if (parsed === null || parsed.output === undefined) {
      return new ImagePollResolution()
    }
    if (parsed.output.task_status === 'SUCCEEDED') {
      const imageUrl = ImageGenerationResponseHelper.extractFirstUrl(parsed.output.results)
      return imageUrl.length > 0
        ? ImageGenerationResponseHelper.buildSuccessResolution(imageUrl)
        : ImageGenerationResponseHelper.buildErrorResolution('获取图片URL失败')
    }
    if (parsed.output.task_status === 'FAILED') {
      const errorMessage = typeof parsed.output.message === 'string' && parsed.output.message.length > 0
        ? parsed.output.message
        : '图片生成失败'
      return ImageGenerationResponseHelper.buildErrorResolution(errorMessage)
    }
    return new ImagePollResolution()
  }

  static extractBase64Image(responseData: string): string {
    const parsed = ImageGenerationResponseHelper.parseJsonPayload<StabilityResponsePayload>(responseData, 'extractBase64Image')
    if (!Array.isArray(parsed.artifacts) || parsed.artifacts.length === 0) {
      return ''
    }
    const firstArtifact = parsed.artifacts[0]
    return typeof firstArtifact.base64 === 'string' ? firstArtifact.base64 : ''
  }

  static extractAccessToken(responseData: string): string {
    const parsed = ImageGenerationResponseHelper.parseJsonPayload<BaiduTokenResponsePayload>(responseData, 'extractAccessToken')
    return typeof parsed.access_token === 'string' ? parsed.access_token : ''
  }

  static extractBaiduTaskId(responseData: string): string {
    const parsed = ImageGenerationResponseHelper.parseJsonPayload<BaiduCreateResponsePayload>(responseData, 'extractBaiduTaskId')
    if (parsed.error_code !== undefined) {
      const errorMessage = typeof parsed.error_msg === 'string' && parsed.error_msg.length > 0
        ? parsed.error_msg
        : '图片生成失败'
      throw new Error(errorMessage)
    }
    return typeof parsed.data?.task_id === 'string' ? parsed.data.task_id : ''
  }

  static resolveBaiduPollResult(responseData: string): ImagePollResolution {
    const parsed = ImageGenerationResponseHelper.tryParseJsonPayload<BaiduPollResponsePayload>(
      responseData,
      'resolveBaiduPollResult'
    )
    if (parsed === null || parsed.data === undefined) {
      return new ImagePollResolution()
    }
    if (parsed.data.task_status === 'SUCCESS') {
      if (!Array.isArray(parsed.data.sub_task_result_list) || parsed.data.sub_task_result_list.length === 0) {
        return ImageGenerationResponseHelper.buildErrorResolution('获取图片URL失败')
      }
      const finalImageList = parsed.data.sub_task_result_list[0].final_image_list
      if (!Array.isArray(finalImageList) || finalImageList.length === 0) {
        return ImageGenerationResponseHelper.buildErrorResolution('获取图片URL失败')
      }
      const firstImage = finalImageList[0]
      if (typeof firstImage.img_url === 'string' && firstImage.img_url.length > 0) {
        return ImageGenerationResponseHelper.buildSuccessResolution(firstImage.img_url)
      }
      return ImageGenerationResponseHelper.buildErrorResolution('获取图片URL失败')
    }
    if (parsed.data.task_status === 'FAILED') {
      return ImageGenerationResponseHelper.buildErrorResolution('图片生成失败')
    }
    return new ImagePollResolution()
  }

  static extractReplicatePollUrl(responseData: string): string {
    const parsed = ImageGenerationResponseHelper.parseJsonPayload<ReplicatePredictionResponsePayload>(
      responseData,
      'extractReplicatePollUrl'
    )
    return typeof parsed.urls?.get === 'string' ? parsed.urls.get : ''
  }

  static resolveReplicatePollResult(responseData: string): ImagePollResolution {
    const parsed = ImageGenerationResponseHelper.tryParseJsonPayload<ReplicatePredictionResponsePayload>(
      responseData,
      'resolveReplicatePollResult'
    )
    if (parsed === null) {
      return new ImagePollResolution()
    }
    if (parsed.status === 'succeeded') {
      let imageUrl = ''
      if (Array.isArray(parsed.output) && parsed.output.length > 0) {
        const firstOutput = parsed.output[0]
        if (typeof firstOutput === 'string') {
          imageUrl = firstOutput
        }
      } else if (typeof parsed.output === 'string') {
        imageUrl = parsed.output
      }
      return imageUrl.length > 0
        ? ImageGenerationResponseHelper.buildSuccessResolution(imageUrl)
        : ImageGenerationResponseHelper.buildErrorResolution('Replicate: 获取图片URL失败')
    }
    if (parsed.status === 'failed') {
      if (typeof parsed.error === 'string' && parsed.error.length > 0) {
        return ImageGenerationResponseHelper.buildErrorResolution(parsed.error)
      }
      return ImageGenerationResponseHelper.buildErrorResolution('图片生成失败')
    }
    return new ImagePollResolution()
  }

  private static extractFirstUrl(items?: ImageUrlItemPayload[]): string {
    if (!Array.isArray(items) || items.length === 0) {
      return ''
    }
    const firstItem = items[0]
    return typeof firstItem.url === 'string' ? firstItem.url : ''
  }

  private static buildSuccessResolution(imageUrl: string): ImagePollResolution {
    const resolution = new ImagePollResolution()
    resolution.isCompleted = true
    resolution.imageUrl = imageUrl
    return resolution
  }

  private static buildErrorResolution(errorMessage: string): ImagePollResolution {
    const resolution = new ImagePollResolution()
    resolution.isCompleted = true
    resolution.errorMessage = errorMessage
    return resolution
  }
}
