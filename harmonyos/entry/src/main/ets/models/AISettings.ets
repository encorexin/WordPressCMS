// AI 设置数据模型

export class AISettingsModel {
  id: string = ''
  userId: string = ''
  name: string = ''
  isDefault: boolean = false
  apiEndpoint: string = ''
  apiKey: string = ''
  model: string = ''
  systemPrompt: string = ''
  imageProvider: string = ''
  imageApiKey: string = ''
  imageEndpoint: string = ''
  imageModel: string = ''
  imageEnabled: boolean = false
  slugModel: string = ''
  slugEnabled: boolean = true
  createdAt: string = ''
  updatedAt: string = ''
}
