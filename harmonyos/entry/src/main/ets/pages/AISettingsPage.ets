// AI 设置页面 — 多 AI 服务商配置管理

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { AISettingsModel } from '../models/AISettings'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { AIStreamClient, ChatMessage } from '../services/http/AIStreamClient'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

// 预设 AI 服务商配置
class ProviderPreset {
  name: string = ''
  endpoint: string = ''
  models: string[] = []
}

const DEFAULT_SYSTEM_PROMPT: string = '你是一名专业的内容创作者和SEO专家。请根据给定的关键词和模板要求，创作高质量、原创的文章内容。文章应该结构清晰、内容丰富、符合SEO最佳实践。'

// 图片生成服务商预设配置
class ImageProviderPreset {
  value: string = ''
  label: string = ''
  endpoint: string = ''
}

const IMAGE_PROVIDERS: ImageProviderPreset[] = [
  { value: 'openai', label: 'OpenAI DALL-E', endpoint: 'https://api.openai.com/v1/images/generations' },
  { value: 'aliyun', label: '阿里云通义万相', endpoint: 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis' },
  { value: 'zhipu', label: '智谱 CogView', endpoint: 'https://open.bigmodel.cn/api/paas/v4/images/generations' },
  { value: 'stability', label: 'Stability AI', endpoint: 'https://api.stability.ai/v2beta/stable-image/generate/sd3' },
  { value: 'baidu', label: '百度文心一格', endpoint: 'https://aip.baidubce.com/rpc/2.0/ernievilg/v1/txt2imgv2' },
  { value: 'siliconflow', label: 'SiliconFlow 硅基流动', endpoint: 'https://api.siliconflow.cn/v1/images/generations' },
  { value: 'replicate', label: 'Replicate', endpoint: 'https://api.replicate.com/v1/predictions' },
  { value: 'custom', label: '自定义端点', endpoint: '' }
]

const PROVIDERS: ProviderPreset[] = [
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

@Component
export struct AISettingsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  @State settingsList: AISettingsModel[] = []
  @State isLoading: boolean = true

  // 表单状态
  @State showForm: boolean = false
  @State editingSettings: AISettingsModel | null = null
  @State formName: string = ''
  @State formProvider: string = ''
  @State formApiEndpoint: string = ''
  @State formApiKey: string = ''
  @State formModel: string = ''
  @State formSystemPrompt: string = ''
  @State isSaving: boolean = false
  @State isTesting: boolean = false
  @State connectionTested: boolean = false
  @State fetchedModels: string[] = []
  @State isFetchingModels: boolean = false

  // 图片生成设置表单状态
  @State formImageEnabled: boolean = false
  @State formImageProvider: string = ''
  @State formImageApiKey: string = ''
  @State formImageEndpoint: string = ''
  @State formImageModel: string = ''

  // Slug 生成设置表单状态
  @State formSlugEnabled: boolean = true
  @State formSlugModel: string = ''

  aboutToAppear(): void {
    this.loadSettings()
  }

  private getProviderOptions(): SelectOption[] {
    const options: SelectOption[] = []
    for (let i = 0; i < PROVIDERS.length; i++) {
      const opt: SelectOption = { value: PROVIDERS[i].name }
      options.push(opt)
    }
    return options
  }

  private getImageProviderOptions(): SelectOption[] {
    const options: SelectOption[] = []
    for (let i = 0; i < IMAGE_PROVIDERS.length; i++) {
      const opt: SelectOption = { value: IMAGE_PROVIDERS[i].label }
      options.push(opt)
    }
    return options
  }

  private getCurrentProviderModels(): string[] {
    if (this.fetchedModels.length > 0) {
      return this.fetchedModels
    }
    for (let i = 0; i < PROVIDERS.length; i++) {
      if (PROVIDERS[i].name === this.formProvider) {
        return PROVIDERS[i].models
      }
    }
    return []
  }

  private getModelOptions(): SelectOption[] {
    const models = this.getCurrentProviderModels()
    const options: SelectOption[] = []
    for (let i = 0; i < models.length; i++) {
      const opt: SelectOption = { value: models[i] }
      options.push(opt)
    }
    return options
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部工具栏
          this.ToolbarArea()

          // 内容区
          if (this.isLoading) {
            this.LoadingView()
          } else if (this.settingsList.length === 0) {
            this.EmptyView()
          } else {
            this.SettingsList()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BG_PRIMARY)

        // 表单弹窗
        if (this.showForm) {
          this.FormDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== 工具栏 ==========

  @Builder
  ToolbarArea() {
    Row() {
      // 标题
      Text('AI 设置')
        .fontSize(Typography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)
        .layoutWeight(1)

      // 添加配置按钮
      Button('添加配置', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.openFormDialog()
        })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 加载中 ==========

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(Colors.PRIMARY)
      Text('加载中...')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ========== 空状态 ==========

  @Builder
  EmptyView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.gearshape'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无 AI 配置')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('添加 AI 配置以开始使用智能功能')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('添加配置', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.openFormDialog()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 设置列表 ==========

  @Builder
  SettingsList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        ForEach(this.settingsList, (settings: AISettingsModel) => {
          this.SettingsCard(settings)
        }, (settings: AISettingsModel) => settings.id)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  SettingsCard(settings: AISettingsModel) {
    Column({ space: Spacing.MD }) {
      // 头部：名称 + 默认标签
      Row() {
        Row({ space: Spacing.SM }) {
          Text(settings.name)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)

          if (settings.isDefault) {
            Text('默认')
              .fontSize(Typography.LABEL)
              .fontColor(Colors.TEXT_ON_PRIMARY)
              .backgroundColor(Colors.PRIMARY)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
              .borderRadius(Radius.FULL)
          }
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 端点信息
      Column({ space: Spacing.XS }) {
        Text(settings.apiEndpoint)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_HINT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 模型
      Row({ space: Spacing.SM }) {
        Text('模型：')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
        Text(settings.model)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      // 操作按钮
      Row({ space: Spacing.SM }) {
        if (!settings.isDefault) {
          Button('设为默认', { type: ButtonType.Normal })
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .onClick(() => {
              this.handleSetDefault(settings)
            })
        }

        Button('编辑', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.openEditDialog(settings)
          })

        Button('删除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.confirmDelete(settings)
          })

        Button(this.isTesting ? '测试中...' : '测试连接', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.SUCCESS)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .enabled(!this.isTesting)
          .onClick(() => {
            this.handleTestConnection(settings)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  // ========== 表单弹窗 ==========

  @Builder
  FormDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.isSaving) {
            this.closeFormDialog()
          }
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
        // 标题 + 关闭
        Row() {
          Text(this.editingSettings !== null ? '编辑配置' : '添加配置')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([Colors.TEXT_HINT])
            .onClick(() => {
              if (!this.isSaving) {
                this.closeFormDialog()
              }
            })
        }
        .width('100%')

        // 可滚动表单
        Scroll() {
          Column({ space: Spacing.MD }) {
            // 配置名称
            Column({ space: Spacing.XS }) {
              Text('配置名称')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: '如：OpenAI 生产环境', text: this.formName })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(Colors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formName = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 服务商选择
            Column({ space: Spacing.XS }) {
              Text('AI 服务商')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Select(this.getProviderOptions())
                .value(this.formProvider.length > 0 ? this.formProvider : '请选择服务商')
                .fontColor(Colors.TEXT_PRIMARY)
                .backgroundColor(Colors.BG_SECONDARY)
                .width('100%')
                .height(ComponentSize.INPUT_HEIGHT)
                .enabled(!this.isSaving)
                .onSelect((index: number) => {
                  const provider = PROVIDERS[index]
                  this.formProvider = provider.name
                  if (provider.endpoint.length > 0) {
                    this.formApiEndpoint = provider.endpoint
                  }
                  if (provider.models.length > 0) {
                    this.formModel = provider.models[0]
                  }
                  this.connectionTested = false
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // API 端点
            Column({ space: Spacing.XS }) {
              Text('API 端点')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: 'https://api.example.com/v1/chat/completions', text: this.formApiEndpoint })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(Colors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formApiEndpoint = value
                  this.connectionTested = false
                })
              Text('通常以 /v1/chat/completions 结尾')
                .fontSize(Typography.CAPTION)
                .fontColor(Colors.TEXT_HINT)
                .margin({ top: 2 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // API 密钥
            Column({ space: Spacing.XS }) {
              Text('API 密钥')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: '输入您的 API Key', text: this.formApiKey })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(Colors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .type(InputType.Password)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formApiKey = value
                  this.connectionTested = false
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 模型选择
            Column({ space: Spacing.XS }) {
              Text('模型')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              if (this.getCurrentProviderModels().length > 0) {
                Select(this.getModelOptions())
                  .value(this.formModel.length > 0 ? this.formModel : '请选择模型')
                  .fontColor(Colors.TEXT_PRIMARY)
                  .backgroundColor(Colors.BG_SECONDARY)
                  .width('100%')
                  .height(ComponentSize.INPUT_HEIGHT)
                  .enabled(!this.isSaving)
                  .onSelect((index: number) => {
                    const models = this.getCurrentProviderModels()
                    if (index >= 0 && index < models.length) {
                      this.formModel = models[index]
                    }
                    this.connectionTested = false
                  })
              }
              TextInput({ placeholder: '输入自定义模型名称', text: this.formModel })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(Colors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formModel = value
                  this.connectionTested = false
                })
              // 获取模型按钮
              Button(this.isFetchingModels ? '获取中...' : '获取模型')
                .type(ButtonType.Normal)
                .fontSize(Typography.BODY)
                .fontColor(Colors.PRIMARY)
                .backgroundColor(Color.Transparent)
                .borderWidth(1)
                .borderColor(Colors.PRIMARY)
                .borderRadius(Radius.SM)
                .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
                .width('100%')
                .margin({ top: Spacing.XS })
                .enabled(!this.isFetchingModels && this.formApiEndpoint.trim().length > 0 && this.formApiKey.trim().length > 0)
                .onClick(() => {
                  this.handleFetchModels()
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 系统提示词
            Column({ space: Spacing.XS }) {
              Text('系统提示词（可选）')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextArea({ placeholder: '定义 AI 的角色和行为...', text: this.formSystemPrompt })
                .height(120)
                .borderRadius(Radius.MD)
                .backgroundColor(Colors.BG_SECONDARY)
                .padding(Spacing.BASE)
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .placeholderColor(Colors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formSystemPrompt = value
                })
              Button('重置为默认', { type: ButtonType.Normal })
                .fontSize(Typography.CAPTION)
                .fontColor(Colors.PRIMARY)
                .backgroundColor(Color.Transparent)
                .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
                .enabled(!this.isSaving)
                .onClick(() => {
                  this.formSystemPrompt = DEFAULT_SYSTEM_PROMPT
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 图片生成设置
            Column({ space: Spacing.XS }) {
              Text('图片生成设置')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)

              // 启用图片生成开关
              Row() {
                Text('启用图片生成')
                  .fontSize(Typography.BODY)
                  .fontColor(Colors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.formImageEnabled })
                  .selectedColor(Colors.PRIMARY)
                  .onChange((isOn: boolean) => {
                    this.formImageEnabled = isOn
                  })
                  .enabled(!this.isSaving)
              }
              .width('100%')

              // 图片生成详细设置（仅在启用时显示）
              if (this.formImageEnabled) {
                // 图片服务商选择
                Column({ space: Spacing.XS }) {
                  Text('图片服务商')
                    .fontSize(Typography.BODY)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  Select(this.getImageProviderOptions())
                    .value(this.formImageProvider.length > 0 ? this.formImageProvider : '请选择服务商')
                    .fontColor(Colors.TEXT_PRIMARY)
                    .backgroundColor(Colors.BG_SECONDARY)
                    .width('100%')
                    .height(ComponentSize.INPUT_HEIGHT)
                    .enabled(!this.isSaving)
                    .onSelect((index: number) => {
                      const provider = IMAGE_PROVIDERS[index]
                      this.formImageProvider = provider.label
                      if (provider.endpoint.length > 0) {
                        this.formImageEndpoint = provider.endpoint
                      }
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: Spacing.SM })

                // 图片 API 密钥
                Column({ space: Spacing.XS }) {
                  Text('图片 API 密钥')
                    .fontSize(Typography.BODY)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '输入图片生成的 API Key', text: this.formImageApiKey })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(Colors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .placeholderColor(Colors.TEXT_HINT)
                    .type(InputType.Password)
                    .enabled(!this.isSaving)
                    .onChange((value: string) => {
                      this.formImageApiKey = value
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: Spacing.SM })

                // 图片端点
                Column({ space: Spacing.XS }) {
                  Text('图片 API 端点')
                    .fontSize(Typography.BODY)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: 'https://api.example.com/v1/images/generations', text: this.formImageEndpoint })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(Colors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .placeholderColor(Colors.TEXT_HINT)
                    .enabled(!this.isSaving)
                    .onChange((value: string) => {
                      this.formImageEndpoint = value
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: Spacing.SM })

                // 图片模型
                Column({ space: Spacing.XS }) {
                  Text('图片模型')
                    .fontSize(Typography.BODY)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '如：dall-e-3, cogview-3 等', text: this.formImageModel })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(Colors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .placeholderColor(Colors.TEXT_HINT)
                    .enabled(!this.isSaving)
                    .onChange((value: string) => {
                      this.formImageModel = value
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: Spacing.SM })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // Slug 生成设置
            Column({ space: Spacing.XS }) {
              Text('Slug 生成设置')
                .fontSize(Typography.BODY)
                .fontColor(Colors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)

              // 启用 Slug 自动生成开关
              Row() {
                Text('启用 Slug 自动生成')
                  .fontSize(Typography.BODY)
                  .fontColor(Colors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.formSlugEnabled })
                  .selectedColor(Colors.PRIMARY)
                  .onChange((isOn: boolean) => {
                    this.formSlugEnabled = isOn
                  })
                  .enabled(!this.isSaving)
              }
              .width('100%')

              // Slug 模型设置（仅在启用时显示）
              if (this.formSlugEnabled) {
                Column({ space: Spacing.XS }) {
                  Text('Slug 生成模型')
                    .fontSize(Typography.BODY)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '留空则使用主 AI 模型', text: this.formSlugModel })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(Colors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(Colors.TEXT_PRIMARY)
                    .placeholderColor(Colors.TEXT_HINT)
                    .enabled(!this.isSaving)
                    .onChange((value: string) => {
                      this.formSlugModel = value
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ top: Spacing.SM })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.LG })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 测试连接按钮
        Button(this.isTesting ? '测试中...' : (this.connectionTested ? '✓ 连接正常' : '测试连接'))
          .type(ButtonType.Capsule)
          .width('100%')
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(this.connectionTested ? Colors.TEXT_ON_PRIMARY : Colors.PRIMARY)
          .backgroundColor(this.connectionTested ? Colors.SUCCESS : Color.Transparent)
          .borderWidth(this.connectionTested ? 0 : 1)
          .borderColor(Colors.PRIMARY)
          .enabled(!this.isTesting && !this.isSaving && this.formApiEndpoint.trim().length > 0 && this.formApiKey.trim().length > 0 && this.formModel.trim().length > 0)
          .onClick(() => {
            this.handleFormTestConnection()
          })
          .margin({ bottom: Spacing.MD })

        // 操作按钮
        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(Colors.TEXT_PRIMARY)
            .backgroundColor(Colors.BG_SECONDARY)
            .enabled(!this.isSaving)
            .onClick(() => {
              this.closeFormDialog()
            })

          Button(this.isSaving ? '保存中...' : '保存', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(Colors.PRIMARY)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.isSaving && this.connectionTested)
            .onClick(() => {
              this.handleSave()
            })
        }
        .width('100%')
        .margin({ top: Spacing.SM })
      }
      .width('100%')
      .height('85%')
      .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
      .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
      .backgroundColor(Colors.BG_PRIMARY)
      .position({ x: 0, y: '100%' })
      .translate({ y: this.showForm ? '-100%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 业务逻辑 ==========

  private async loadSettings(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      this.settingsList = await AISettingsDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load AI settings failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载配置失败' })
    } finally {
      this.isLoading = false
    }
  }

  private openFormDialog(): void {
    this.editingSettings = null
    this.formName = ''
    this.formProvider = ''
    this.formApiEndpoint = ''
    this.formApiKey = ''
    this.formModel = ''
    this.formSystemPrompt = ''
    this.connectionTested = false
    this.fetchedModels = []
    this.isFetchingModels = false
    // 重置图片生成设置
    this.formImageEnabled = false
    this.formImageProvider = ''
    this.formImageApiKey = ''
    this.formImageEndpoint = ''
    this.formImageModel = ''
    // 重置 Slug 生成设置
    this.formSlugEnabled = true
    this.formSlugModel = ''
    this.showForm = true
  }

  private openEditDialog(settings: AISettingsModel): void {
    this.editingSettings = settings
    this.formName = settings.name
    this.formProvider = this.inferProvider(settings.apiEndpoint)
    this.formApiEndpoint = settings.apiEndpoint
    this.formApiKey = settings.apiKey
    this.formModel = settings.model
    this.formSystemPrompt = settings.systemPrompt
    this.connectionTested = true
    this.fetchedModels = []
    this.isFetchingModels = false
    // 加载图片生成设置
    this.formImageEnabled = settings.imageEnabled
    this.formImageProvider = settings.imageProvider
    this.formImageApiKey = settings.imageApiKey
    this.formImageEndpoint = settings.imageEndpoint
    this.formImageModel = settings.imageModel
    // 加载 Slug 生成设置
    this.formSlugEnabled = settings.slugEnabled
    this.formSlugModel = settings.slugModel
    this.showForm = true
  }

  private inferProvider(endpoint: string): string {
    for (let i = 0; i < PROVIDERS.length; i++) {
      if (endpoint === PROVIDERS[i].endpoint) {
        return PROVIDERS[i].name
      }
    }
    return '自定义'
  }

  private closeFormDialog(): void {
    this.showForm = false
    this.editingSettings = null
  }

  private async handleSave(): Promise<void> {
    if (this.formName.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入配置名称' })
      return
    }
    if (this.formApiEndpoint.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入 API 端点' })
      return
    }
    if (this.formApiKey.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入 API 密钥' })
      return
    }
    if (this.formModel.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入或选择模型' })
      return
    }

    this.isSaving = true
    try {
      if (this.editingSettings !== null) {
        // 更新
        const settings = this.editingSettings
        settings.name = this.formName.trim()
        settings.apiEndpoint = this.formApiEndpoint.trim()
        settings.apiKey = this.formApiKey.trim()
        settings.model = this.formModel.trim()
        settings.systemPrompt = this.formSystemPrompt.trim()
        // 更新图片生成设置
        settings.imageEnabled = this.formImageEnabled
        settings.imageProvider = this.formImageProvider.trim()
        settings.imageApiKey = this.formImageApiKey.trim()
        settings.imageEndpoint = this.formImageEndpoint.trim()
        settings.imageModel = this.formImageModel.trim()
        // 更新 Slug 生成设置
        settings.slugEnabled = this.formSlugEnabled
        settings.slugModel = this.formSlugModel.trim()
        await AISettingsDao.update(settings)
        UiFeedback.showToast({ message: '配置已更新', duration: 2000 })
      } else {
        // 新建
        const settings = new AISettingsModel()
        settings.userId = this.currentUserId
        settings.name = this.formName.trim()
        settings.apiEndpoint = this.formApiEndpoint.trim()
        settings.apiKey = this.formApiKey.trim()
        settings.model = this.formModel.trim()
        settings.systemPrompt = this.formSystemPrompt.trim()
        settings.isDefault = this.settingsList.length === 0
        // 设置图片生成设置
        settings.imageEnabled = this.formImageEnabled
        settings.imageProvider = this.formImageProvider.trim()
        settings.imageApiKey = this.formImageApiKey.trim()
        settings.imageEndpoint = this.formImageEndpoint.trim()
        settings.imageModel = this.formImageModel.trim()
        // 设置 Slug 生成设置
        settings.slugEnabled = this.formSlugEnabled
        settings.slugModel = this.formSlugModel.trim()
        await AISettingsDao.insert(settings)
        UiFeedback.showToast({ message: '配置已添加', duration: 2000 })
      }
      this.closeFormDialog()
      await this.loadSettings()
    } catch (err) {
      Logger.error('Save AI settings failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '保存失败' })
    } finally {
      this.isSaving = false
    }
  }

  private async handleSetDefault(settings: AISettingsModel): Promise<void> {
    try {
      await AISettingsDao.setDefault(this.currentUserId, settings.id)
      UiFeedback.showToast({ message: '已设为默认配置', duration: 2000 })
      await this.loadSettings()
    } catch (err) {
      Logger.error('Set default settings failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '设置失败' })
    }
  }

  private confirmDelete(settings: AISettingsModel): void {
    UiFeedback.showConfirm({
      title: '确认删除',
      message: `确定要删除配置"${settings.name}"吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: Colors.ERROR,
        action: () => {
          this.handleDelete(settings)
        }
      }
    })
  }

  private async handleDelete(settings: AISettingsModel): Promise<void> {
    try {
      await AISettingsDao.deleteById(settings.id)
      UiFeedback.showToast({ message: '配置已删除', duration: 2000 })
      await this.loadSettings()
    } catch (err) {
      Logger.error('Delete AI settings failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }

  private async handleTestConnection(settings: AISettingsModel): Promise<void> {
    if (settings.apiEndpoint.length === 0 || settings.apiKey.length === 0) {
      UiFeedback.showToast({ message: 'API 配置不完整' })
      return
    }

    this.isTesting = true
    try {
      const messages: ChatMessage[] = []
      const msg = new ChatMessage()
      msg.role = 'user'
      msg.content = 'Hello, this is a connection test. Please reply with "OK" only.'
      messages.push(msg)

      const result = await AIStreamClient.sendOnce(
        settings.apiEndpoint,
        settings.apiKey,
        settings.model,
        messages
      )

      if (result.length > 0) {
        UiFeedback.showToast({ message: '连接测试成功', duration: 2000 })
      } else {
        UiFeedback.showToast({ message: '连接测试失败：无响应' })
      }
    } catch (err) {
      Logger.error('Test connection failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '连接测试失败' })
    } finally {
      this.isTesting = false
    }
  }

  private async handleFetchModels(): Promise<void> {
    this.isFetchingModels = true
    try {
      const models = await AIStreamClient.fetchModels(this.formApiEndpoint.trim(), this.formApiKey.trim())
      if (models.length > 0) {
        this.fetchedModels = models
        this.formModel = models[0]
        UiFeedback.showToast({ message: `成功获取 ${models.length} 个模型`, duration: 2000 })
      } else {
        UiFeedback.showToast({ message: '未获取到模型列表' })
      }
    } catch (err) {
      Logger.error('Fetch models failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '获取模型失败' })
    } finally {
      this.isFetchingModels = false
    }
  }

  private async handleFormTestConnection(): Promise<void> {
    this.isTesting = true
    try {
      const messages: ChatMessage[] = []
      const msg = new ChatMessage()
      msg.role = 'user'
      msg.content = 'Hello, this is a connection test. Please reply with "OK" only.'
      messages.push(msg)

      const result = await AIStreamClient.sendOnce(
        this.formApiEndpoint.trim(),
        this.formApiKey.trim(),
        this.formModel.trim(),
        messages
      )

      if (result.length > 0) {
        this.connectionTested = true
        UiFeedback.showToast({ message: '连接测试成功', duration: 2000 })
      } else {
        this.connectionTested = false
        UiFeedback.showToast({ message: '连接测试失败：无响应' })
      }
    } catch (err) {
      this.connectionTested = false
      Logger.error('Form test connection failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '连接测试失败' })
    } finally {
      this.isTesting = false
    }
  }
}
