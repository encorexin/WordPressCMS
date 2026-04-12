// 图片生成服务请求体与提示词辅助方法

export class ImageGenerationPromptBuilder {
  static buildOpenAIBody(prompt: string, model: string): string {
    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
      'response_format': 'url'
    }
    return JSON.stringify(bodyObj)
  }

  static buildAliyunBody(prompt: string, model: string): string {
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
    return JSON.stringify(bodyObj)
  }

  static buildZhipuBody(prompt: string, model: string): string {
    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'size': '1024x1024'
    }
    return JSON.stringify(bodyObj)
  }

  static buildStabilityBody(prompt: string): string {
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
    return JSON.stringify(bodyObj)
  }

  static buildBaiduCreateBody(prompt: string): string {
    const bodyObj: Record<string, Object> = {
      'prompt': prompt,
      'width': 1024,
      'height': 1024,
      'image_num': 1
    }
    return JSON.stringify(bodyObj)
  }

  static buildBaiduQueryBody(taskId: string): string {
    const bodyObj: Record<string, Object> = {
      'task_id': taskId
    }
    return JSON.stringify(bodyObj)
  }

  static buildSiliconFlowBody(prompt: string, model: string): string {
    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'image_size': '1024x1024',
      'batch_size': 1,
      'num_inference_steps': 20
    }
    return JSON.stringify(bodyObj)
  }

  static buildReplicateBody(prompt: string, model: string): string {
    const inputObj: Record<string, Object> = {
      'prompt': prompt,
      'width': 1024,
      'height': 1024
    }
    const bodyObj: Record<string, Object> = {
      'version': model,
      'input': inputObj
    }
    return JSON.stringify(bodyObj)
  }

  static buildCustomBody(prompt: string, model: string): string {
    const bodyObj: Record<string, Object> = {
      'model': model,
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024'
    }
    return JSON.stringify(bodyObj)
  }

  static generateImagePrompt(keywords: string, title: string): string {
    return 'A professional, high-quality illustration for an article about "' + title +
      '". Keywords: ' + keywords +
      '. Style: modern, clean, professional, suitable for blog post header image. No text or watermarks.'
  }

  static insertImageToContent(content: string, imageUrl: string, alt: string): string {
    const imageMarkdown: string = '![' + alt + '](' + imageUrl + ')\n\n'
    return imageMarkdown + content
  }
}
