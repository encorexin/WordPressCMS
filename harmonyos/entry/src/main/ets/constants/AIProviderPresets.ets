// AI 服务商与图片服务商预设

export class ProviderPreset {
  name: string = ''
  endpoint: string = ''
  models: string[] = []
}

export class ImageProviderPreset {
  value: string = ''
  label: string = ''
  endpoint: string = ''
}

export const DEFAULT_SYSTEM_PROMPT: string =
  '你是一名专业的内容创作者和SEO专家。请根据给定的关键词和模板要求，创作高质量、原创的文章内容。文章应该结构清晰、内容丰富、符合SEO最佳实践。'

export const IMAGE_PROVIDERS: ImageProviderPreset[] = [
  { value: 'openai', label: 'OpenAI DALL-E', endpoint: 'https://api.openai.com/v1/images/generations' },
  { value: 'aliyun', label: '阿里云通义万相', endpoint: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis' },
  { value: 'zhipu', label: '智谱 CogView', endpoint: 'https://open.bigmodel.cn/api/paas/v4/images/generations' },
  { value: 'stability', label: 'Stability AI', endpoint: 'https://api.stability.ai/v2beta/stable-image/generate/sd3' },
  { value: 'baidu', label: '百度文心一格', endpoint: 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2' },
  { value: 'siliconflow', label: 'SiliconFlow 硅基流动', endpoint: 'https://api.siliconflow.cn/v1/images/generations' },
  { value: 'replicate', label: 'Replicate', endpoint: 'https://api.replicate.com/v1/predictions' },
  { value: 'custom', label: '自定义端点', endpoint: '' }
]

export const PROVIDERS: ProviderPreset[] = [
  {
    name: 'OpenAI',
    endpoint: 'https://api.openai.com/v1/chat/completions',
    models: ['gpt-5.4', 'gpt-5.4-mini', 'gpt-4o']
  },
  {
    name: 'Anthropic',
    endpoint: 'https://api.anthropic.com/v1/messages',
    models: ['claude-opus-4.6', 'claude-sonnet-4.6', 'claude-haiku-4.5']
  },
  {
    name: 'DeepSeek',
    endpoint: 'https://api.deepseek.com/v1/chat/completions',
    models: ['deepseek-chat', 'deepseek-reasoner']
  },
  {
    name: 'Google',
    endpoint: 'https://generativelanguage.googleapis.com/v1beta/chat/completions',
    models: ['gemini-3.1-pro', 'gemini-3.1-flash', 'gemini-2.5-pro']
  },
  {
    name: '阿里云百炼',
    endpoint: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
    models: ['qwen3.6-plus', 'qwen3.5', 'qwen2.5']
  },
  {
    name: '智谱AI',
    endpoint: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    models: ['glm-5.1', 'glm-5', 'glm-4']
  },
  {
    name: 'Moonshot',
    endpoint: 'https://api.moonshot.cn/v1/chat/completions',
    models: ['kimi-k2.5', 'kimi-k2', 'moonshot-v1-32k']
  },
  {
    name: 'SiliconFlow',
    endpoint: 'https://api.siliconflow.cn/v1/chat/completions',
    models: ['deepseek-ai/DeepSeek-V3.2', 'Qwen/Qwen3-8B']
  },
  {
    name: 'Groq',
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    models: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant', 'mixtral-8x7b-32768']
  },
  {
    name: 'Together AI',
    endpoint: 'https://api.together.xyz/v1/chat/completions',
    models: ['meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo', 'meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo']
  },
  {
    name: 'OpenRouter',
    endpoint: 'https://openrouter.ai/api/v1/chat/completions',
    models: ['openai/gpt-5.4', 'anthropic/claude-opus-4.6', 'google/gemini-3.1-pro']
  },
  {
    name: '自定义',
    endpoint: '',
    models: []
  }
]

export function buildProviderOptions(): SelectOption[] {
  const options: SelectOption[] = []
  for (let i = 0; i < PROVIDERS.length; i++) {
    options.push({ value: PROVIDERS[i].name })
  }
  return options
}

export function buildImageProviderOptions(): SelectOption[] {
  const options: SelectOption[] = []
  for (let i = 0; i < IMAGE_PROVIDERS.length; i++) {
    options.push({ value: IMAGE_PROVIDERS[i].label })
  }
  return options
}

export function getProviderModels(providerName: string, fetchedModels: string[] = []): string[] {
  if (fetchedModels.length > 0) {
    return fetchedModels
  }
  for (let i = 0; i < PROVIDERS.length; i++) {
    if (PROVIDERS[i].name === providerName) {
      return PROVIDERS[i].models
    }
  }
  return []
}

export function buildModelOptions(models: string[]): SelectOption[] {
  const options: SelectOption[] = []
  for (let i = 0; i < models.length; i++) {
    options.push({ value: models[i] })
  }
  return options
}

export function inferProviderName(endpoint: string): string {
  for (let i = 0; i < PROVIDERS.length; i++) {
    if (endpoint === PROVIDERS[i].endpoint) {
      return PROVIDERS[i].name
    }
  }
  return '自定义'
}
