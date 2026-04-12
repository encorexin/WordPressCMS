// AI 设置页面 — 多 AI 服务商配置管理

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import {
  DEFAULT_SYSTEM_PROMPT,
  IMAGE_PROVIDERS,
  PROVIDERS,
  buildImageProviderOptions,
  buildModelOptions,
  buildProviderOptions,
  getProviderModels,
  inferProviderName
} from '../constants/AIProviderPresets'
import { AISettingsModel } from '../models/AISettings'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { AIStreamClient } from '../services/http/AIStreamClient'
import { AISettingsContentSectionComponent } from '../components/settings/AISettingsContentSection'
import { AISettingsHeaderPanelComponent } from '../components/settings/AISettingsHeaderPanel'
import { AISettingsConnectionHelper } from '../utils/AISettingsConnectionHelper'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { BasicDataSource } from '../utils/BasicDataSource'
import { AppStorageKeys } from '../constants/AppStorageKeys'
@Component
export struct AISettingsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''
  @State settingsList: AISettingsModel[] = []
  @State isLoading: boolean = true
  private settingsDataSource: BasicDataSource<AISettingsModel> = new BasicDataSource<AISettingsModel>([])
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
  @State formImageEnabled: boolean = false
  @State formImageProvider: string = ''
  @State formImageApiKey: string = ''
  @State formImageEndpoint: string = ''
  @State formImageModel: string = ''
  @State formSlugEnabled: boolean = true
  @State formSlugModel: string = ''
  aboutToAppear(): void {
    this.loadSettings()
  }
  build() {
    NavDestination() {
      Stack() {
        Column() {
          AISettingsHeaderPanelComponent({
            onOpenAdd: () => {
              this.openFormDialog()
            }
          })
          AISettingsContentSectionComponent({
            isLoading: this.isLoading,
            isTesting: this.isTesting,
            dataSource: this.settingsDataSource,
            onOpenAdd: () => {
              this.openFormDialog()
            },
            onSetDefault: (settings: AISettingsModel) => {
              this.handleSetDefault(settings)
            },
            onEdit: (settings: AISettingsModel) => {
              this.openEditDialog(settings)
            },
            onDelete: (settings: AISettingsModel) => {
              this.confirmDelete(settings)
            },
            onTest: (settings: AISettingsModel) => {
              this.handleTestConnection(settings)
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.BG_PRIMARY)
        if (this.showForm) {
          this.FormDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  @Builder
  FormDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          if (!this.isSaving) {
            this.closeFormDialog()
          }
        })
      Column({ space: Spacing.BASE }) {
        Row() {
          Text(this.editingSettings !== null ? '编辑配置' : '添加配置')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .layoutWeight(1)
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_HINT])
            .onClick(() => {
              if (!this.isSaving) {
                this.closeFormDialog()
              }
            })
        }
        .width('100%')
        Scroll() {
          Column({ space: Spacing.MD }) {
            Column({ space: Spacing.XS }) {
              Text('配置名称')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: '如：OpenAI 生产环境', text: this.formName })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(ResourceColors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .placeholderColor(ResourceColors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formName = value
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: Spacing.XS }) {
              Text('AI 服务商')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              Select(buildProviderOptions())
                .value(this.formProvider.length > 0 ? this.formProvider : '请选择服务商')
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .backgroundColor(ResourceColors.BG_SECONDARY)
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

            Column({ space: Spacing.XS }) {
              Text('API 端点')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: 'https://api.example.com/v1/chat/completions', text: this.formApiEndpoint })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(ResourceColors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .placeholderColor(ResourceColors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formApiEndpoint = value
                  this.connectionTested = false
                })
              Text('通常以 /v1/chat/completions 结尾')
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.TEXT_HINT)
                .margin({ top: 2 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: Spacing.XS }) {
              Text('API 密钥')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextInput({ placeholder: '输入您的 API Key', text: this.formApiKey })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(ResourceColors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .placeholderColor(ResourceColors.TEXT_HINT)
                .type(InputType.Password)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formApiKey = value
                  this.connectionTested = false
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Column({ space: Spacing.XS }) {
              Text('模型')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              if (getProviderModels(this.formProvider, this.fetchedModels).length > 0) {
                Select(buildModelOptions(getProviderModels(this.formProvider, this.fetchedModels)))
                  .value(this.formModel.length > 0 ? this.formModel : '请选择模型')
                  .fontColor(ResourceColors.TEXT_PRIMARY)
                  .backgroundColor(ResourceColors.BG_SECONDARY)
                  .width('100%')
                  .height(ComponentSize.INPUT_HEIGHT)
                  .enabled(!this.isSaving)
                  .onSelect((index: number) => {
                    const models = getProviderModels(this.formProvider, this.fetchedModels)
                    if (index >= 0 && index < models.length) {
                      this.formModel = models[index]
                    }
                    this.connectionTested = false
                  })
              }
              TextInput({ placeholder: '输入自定义模型名称', text: this.formModel })
                .height(ComponentSize.INPUT_HEIGHT)
                .borderRadius(Radius.MD)
                .backgroundColor(ResourceColors.BG_SECONDARY)
                .padding({ left: Spacing.BASE, right: Spacing.BASE })
                .fontSize(Typography.BODY_LARGE)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .placeholderColor(ResourceColors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formModel = value
                  this.connectionTested = false
                })
              // 获取模型按钮
              Button(this.isFetchingModels ? '获取中...' : '获取模型')
                .type(ButtonType.Normal)
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.PRIMARY)
                .backgroundColor(Color.Transparent)
                .borderWidth(1)
                .borderColor(ResourceColors.PRIMARY)
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
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)
              TextArea({ placeholder: '定义 AI 的角色和行为...', text: this.formSystemPrompt })
                .height(120)
                .borderRadius(Radius.MD)
                .backgroundColor(ResourceColors.BG_SECONDARY)
                .padding(Spacing.BASE)
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .placeholderColor(ResourceColors.TEXT_HINT)
                .enabled(!this.isSaving)
                .onChange((value: string) => {
                  this.formSystemPrompt = value
                })
              Button('重置为默认', { type: ButtonType.Normal })
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.PRIMARY)
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
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)

              // 启用图片生成开关
              Row() {
                Text('启用图片生成')
                  .fontSize(Typography.BODY)
                  .fontColor(ResourceColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.formImageEnabled })
                  .selectedColor(ResourceColors.PRIMARY)
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
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  Select(buildImageProviderOptions())
                    .value(this.formImageProvider.length > 0 ? this.formImageProvider : '请选择服务商')
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .backgroundColor(ResourceColors.BG_SECONDARY)
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
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '输入图片生成的 API Key', text: this.formImageApiKey })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(ResourceColors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .placeholderColor(ResourceColors.TEXT_HINT)
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
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: 'https://api.example.com/v1/images/generations', text: this.formImageEndpoint })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(ResourceColors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .placeholderColor(ResourceColors.TEXT_HINT)
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
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '如：dall-e-3, cogview-3 等', text: this.formImageModel })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(ResourceColors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .placeholderColor(ResourceColors.TEXT_HINT)
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
                .fontColor(ResourceColors.TEXT_PRIMARY)
                .fontWeight(FontWeight.Medium)

              // 启用 Slug 自动生成开关
              Row() {
                Text('启用 Slug 自动生成')
                  .fontSize(Typography.BODY)
                  .fontColor(ResourceColors.TEXT_PRIMARY)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.formSlugEnabled })
                  .selectedColor(ResourceColors.PRIMARY)
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
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                  TextInput({ placeholder: '留空则使用主 AI 模型', text: this.formSlugModel })
                    .height(ComponentSize.INPUT_HEIGHT)
                    .borderRadius(Radius.MD)
                    .backgroundColor(ResourceColors.BG_SECONDARY)
                    .padding({ left: Spacing.BASE, right: Spacing.BASE })
                    .fontSize(Typography.BODY_LARGE)
                    .fontColor(ResourceColors.TEXT_PRIMARY)
                    .placeholderColor(ResourceColors.TEXT_HINT)
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
          .fontColor(this.connectionTested ? ResourceColors.TEXT_ON_PRIMARY : ResourceColors.PRIMARY)
          .backgroundColor(this.connectionTested ? ResourceColors.SUCCESS : Color.Transparent)
          .borderWidth(this.connectionTested ? 0 : 1)
          .borderColor(ResourceColors.PRIMARY)
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
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .enabled(!this.isSaving)
            .onClick(() => {
              this.closeFormDialog()
            })

          Button(this.isSaving ? '保存中...' : '保存', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(ResourceColors.PRIMARY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
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
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .position({ x: 0, y: '100%' })
      .translate({ y: this.showForm ? '-100%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  private async loadSettings(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      this.settingsList = []
      this.settingsDataSource.setData(this.settingsList)
      return
    }
    try {
      this.isLoading = true
      this.settingsList = await AISettingsDao.findByUserId(this.currentUserId)
      this.settingsDataSource.setData(this.settingsList)
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
    this.formImageEnabled = false
    this.formImageProvider = ''
    this.formImageApiKey = ''
    this.formImageEndpoint = ''
    this.formImageModel = ''
    this.formSlugEnabled = true
    this.formSlugModel = ''
    this.showForm = true
  }

  private openEditDialog(settings: AISettingsModel): void {
    this.editingSettings = settings
    this.formName = settings.name
    this.formProvider = inferProviderName(settings.apiEndpoint)
    this.formApiEndpoint = settings.apiEndpoint
    this.formApiKey = settings.apiKey
    this.formModel = settings.model
    this.formSystemPrompt = settings.systemPrompt
    this.connectionTested = true
    this.fetchedModels = []
    this.isFetchingModels = false
    this.formImageEnabled = settings.imageEnabled
    this.formImageProvider = settings.imageProvider
    this.formImageApiKey = settings.imageApiKey
    this.formImageEndpoint = settings.imageEndpoint
    this.formImageModel = settings.imageModel
    this.formSlugEnabled = settings.slugEnabled
    this.formSlugModel = settings.slugModel
    this.showForm = true
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
        const settings = this.editingSettings
        settings.name = this.formName.trim()
        settings.apiEndpoint = this.formApiEndpoint.trim()
        settings.apiKey = this.formApiKey.trim()
        settings.model = this.formModel.trim()
        settings.systemPrompt = this.formSystemPrompt.trim()
        settings.imageEnabled = this.formImageEnabled
        settings.imageProvider = this.formImageProvider.trim()
        settings.imageApiKey = this.formImageApiKey.trim()
        settings.imageEndpoint = this.formImageEndpoint.trim()
        settings.imageModel = this.formImageModel.trim()
        settings.slugEnabled = this.formSlugEnabled
        settings.slugModel = this.formSlugModel.trim()
        await AISettingsDao.update(settings)
        UiFeedback.showToast({ message: '配置已更新', duration: 2000 })
      } else {
        const settings = new AISettingsModel()
        settings.userId = this.currentUserId
        settings.name = this.formName.trim()
        settings.apiEndpoint = this.formApiEndpoint.trim()
        settings.apiKey = this.formApiKey.trim()
        settings.model = this.formModel.trim()
        settings.systemPrompt = this.formSystemPrompt.trim()
        settings.isDefault = this.settingsList.length === 0
        settings.imageEnabled = this.formImageEnabled
        settings.imageProvider = this.formImageProvider.trim()
        settings.imageApiKey = this.formImageApiKey.trim()
        settings.imageEndpoint = this.formImageEndpoint.trim()
        settings.imageModel = this.formImageModel.trim()
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
        fontColor: ResourceColors.ERROR,
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
      const result = await AISettingsConnectionHelper.requestConnectionPreview(
        settings.apiEndpoint,
        settings.apiKey,
        settings.model
      )

      if (result.length > 0) {
        const preview = AISettingsConnectionHelper.formatPreview(result)
        UiFeedback.showToast({ message: `连接成功：${preview}`, duration: 3000 })
      } else {
        UiFeedback.showToast({ message: '连接测试失败：无响应内容' })
      }
    } catch (err) {
      const errMsg = String(err)
      const brief = AISettingsConnectionHelper.formatError(errMsg)
      Logger.error('Test connection failed: %{public}s', errMsg)
      UiFeedback.showToast({ message: `连接失败：${brief}`, duration: 3000 })
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
      const result = await AISettingsConnectionHelper.requestConnectionPreview(
        this.formApiEndpoint.trim(),
        this.formApiKey.trim(),
        this.formModel.trim()
      )

      if (result.length > 0) {
        this.connectionTested = true
        const preview = AISettingsConnectionHelper.formatPreview(result)
        UiFeedback.showToast({ message: `连接成功：${preview}`, duration: 3000 })
      } else {
        this.connectionTested = false
        UiFeedback.showToast({ message: '连接测试失败：无响应内容' })
      }
    } catch (err) {
      this.connectionTested = false
      const errMsg = String(err)
      const brief = AISettingsConnectionHelper.formatError(errMsg)
      Logger.error('Form test connection failed: %{public}s', errMsg)
      UiFeedback.showToast({ message: `连接失败：${brief}`, duration: 3000 })
    } finally {
      this.isTesting = false
    }
  }
}
