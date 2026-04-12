// 文章编辑器页面 — P0 核心页面
// 功能: 标题/关键词/内容编辑、AI 流式生成、WordPress 发布、模板/主题选择、版本历史

import http from '@ohos.net.http'
import { picker } from '@kit.CoreFileKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { webview } from '@kit.ArkWeb'
import { ConfigurationConstant } from '@kit.AbilityKit'
import { ArticleEditorFormatToolbarComponent } from '../components/article/ArticleEditorFormatToolbar'
import { ArticleEditorPanelTabsComponent } from '../components/article/ArticleEditorPanelTabs'
import { ArticlePreviewSheetComponent } from '../components/article/ArticlePreviewSheet'
import { ArticlePublishPanelComponent } from '../components/article/ArticlePublishPanel'
import { ArticleSiteQuickSelectComponent } from '../components/article/ArticleSiteQuickSelect'
import { ArticleVersionPanelComponent } from '../components/article/ArticleVersionPanel'
import { UiFeedback } from '../utils/UiFeedback'
import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes, ArticleEditorNavParam } from '../constants/Routes'
import { Article } from '../models/Article'
import { ArticleTemplate } from '../models/ArticleTemplate'
import { AISettingsModel } from '../models/AISettings'
import { Topic } from '../models/Topic'
import { WordPressSite } from '../models/WordPressSite'
import { ArticleVersion } from '../models/ArticleVersion'
import { WordPressCategory, WordPressApi } from '../services/http/WordPressApi'
import { AIStreamClient, ChatMessage, StreamOptions } from '../services/http/AIStreamClient'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { TemplateDao } from '../services/db/TemplateDao'
import { TopicDao } from '../services/db/TopicDao'
import { VersionDao } from '../services/db/VersionDao'
import { ArticleExportHelper } from '../utils/ArticleExportHelper'
import { Logger } from '../utils/Logger'
import { ImageGenerationService, ImageGenerationConfig, GeneratedImage, IMAGE_PROVIDERS, ImageProviderInfo } from '../services/ai/ImageGenerationService'
import { ContentMetrics } from '../utils/ContentMetrics'
import { AppStorageKeys, ThemeMode } from '../constants/AppStorageKeys'

@Component
export struct ArticleEditorPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''
  @StorageLink(AppStorageKeys.THEME_MODE) @Watch('onThemeChanged') themeMode: ThemeMode = ThemeMode.System
  @StorageLink(AppStorageKeys.SYSTEM_COLOR_MODE) @Watch('onThemeChanged') systemColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT

  // 编辑器模式: 'new' | 已有 articleId
  @State articleId: string = ''
  @State isNew: boolean = true

  // 文章表单
  @State title: string = ''
  @State content: string = ''
  @State keywords: string = ''
  @State templateName: string = ''
  @State siteId: string = ''
  @State wordpressPostId: string = ''
  @State articleStatus: string = 'draft'

  // 数据源
  @State sites: WordPressSite[] = []
  @State templates: ArticleTemplate[] = []
  @State topics: Topic[] = []
  @State aiSettingsList: AISettingsModel[] = []

  // 选中状态
  @State selectedTemplateId: string = ''
  @State selectedAiSettingsId: string = ''
  @State selectedTopicId: string = ''

  // WordPress 发布相关
  @State wpCategories: WordPressCategory[] = []
  @State selectedCategories: number[] = []
  @State postSlug: string = ''

  // 生成状态
  @State generating: boolean = false
  @State generatingSlug: boolean = false
  @State publishing: boolean = false
  @State saving: boolean = false
  @State generateProgress: number = 0
  @State followGeneratingTail: boolean = true

  // 版本历史
  @State versions: ArticleVersion[] = []
  @State expandedVersionIds: string[] = []

  // AI 流请求引用
  private streamRequest: http.HttpRequest | null = null
  private generateProgressTimer: number | null = null
  private activeGenerationId: number = 0
  private generatingContentScroller: Scroller = new Scroller()
  private generatingAutoScrollTimer: number | null = null

  // 当前活跃面板
  @State activePanel: string = 'ai' // 'ai' | 'publish' | 'version'

  // 编辑器模式
  @State editorMode: string = 'markdown'  // 'markdown' | 'plain'
  @State isPreviewOpen: boolean = false
  @State previewUrl: string = ''
  @State articleTokensUsed: number = 0
  @State lastGenerationTokens: number = 0

  // 图片生成
  @State showImageDialog: boolean = false
  @State imagePrompt: string = ''
  @State generatingImage: boolean = false
  @State imageStatus: string = ''
  @State imageProvider: string = 'openai'
  @State imageApiKey: string = ''
  @State imageEndpoint: string = ''
  @State imageModel: string = ''

  aboutToAppear(): void {
    this.initializeFromParams()
    this.loadData()
  }

  aboutToDisappear(): void {
    // 中止流式请求
    if (this.streamRequest) {
      AIStreamClient.abortStream(this.streamRequest)
    }
    this.cleanupGenerationState(0)
  }

  async loadData(): Promise<void> {
    if (this.currentUserId.length === 0) return

    // 并行加载数据
    try {
      const sitesPromise = SiteDao.findByUserId(this.currentUserId)
      const templatesPromise = TemplateDao.findByUserId(this.currentUserId)
      const topicsPromise = TopicDao.findByUserId(this.currentUserId, -1) // 加载全部主题（含已使用），确保从主题库跳转时能匹配 selectedTopicId
      const aiSettingsPromise = AISettingsDao.findByUserId(this.currentUserId)

      this.sites = await sitesPromise
      this.templates = await templatesPromise
      this.topics = await topicsPromise
      this.aiSettingsList = this.sortAiSettingsList(await aiSettingsPromise)
      this.syncSelectedAiSettingsId()

      // 加载图片生成设置
      const defaultSettings = this.aiSettingsList.find((s: AISettingsModel) => s.isDefault === true)
      if (defaultSettings) {
        this.imageProvider = defaultSettings.imageProvider.length > 0 ? defaultSettings.imageProvider : 'openai'
        this.imageApiKey = defaultSettings.imageApiKey
        this.imageEndpoint = defaultSettings.imageEndpoint
        this.imageModel = defaultSettings.imageModel
      }

      // 新建文章时预设默认模板，保证首次保存写入完整状态
      if (this.isNew && this.templates.length > 0 && this.templateName.length === 0) {
        this.selectedTemplateId = this.templates[0].id
        this.templateName = this.templates[0].name
      }

      // 加载已有文章
      if (!this.isNew && this.articleId.length > 0) {
        await this.loadArticle()
      }
    } catch (err) {
      Logger.error('ArticleEditor loadData failed: %{public}s', String(err))
    }
  }

  private initializeFromParams(): void {
    const params = this.navPathStack.getParamByName(Routes.ARTICLE_EDITOR) as ArticleEditorNavParam[]
    const param = params && params.length > 0 ? params[params.length - 1] : undefined
    const articleId = param ? param.articleId : 'new'
    const sourceType = param ? param.sourceType : 'article'
    const sourceId = param ? param.sourceId : ''
    const initialTitle = param ? param.initialTitle : ''
    const initialKeywords = param ? param.initialKeywords : ''

    this.selectedTopicId = ''
    this.title = ''
    this.content = ''
    this.keywords = ''
    this.templateName = ''
    this.siteId = ''
    this.wordpressPostId = ''
    this.articleStatus = 'draft'
    this.selectedTemplateId = ''
    this.selectedCategories = []
    this.postSlug = ''
    this.wpCategories = []
    this.versions = []
    this.activePanel = 'ai'

    if (articleId !== 'new') {
      this.articleId = articleId
      this.isNew = false
      return
    }

    this.articleId = ''
    this.isNew = true
    this.title = initialTitle
    this.keywords = initialKeywords

    if (sourceType === 'topic' && sourceId.length > 0) {
      this.selectedTopicId = sourceId
    }
  }

  async loadArticle(): Promise<void> {
    const article = await ArticleDao.findById(this.articleId)
    if (article) {
      this.title = article.title
      this.content = article.content
      this.keywords = article.keywords
      this.articleStatus = article.status.length > 0 ? article.status : 'draft'
      this.applyTemplateState(article.template)
      this.siteId = article.siteId
      this.wordpressPostId = article.wordpressPostId
      this.articleTokensUsed = article.tokensUsed
      this.lastGenerationTokens = 0

      // 加载 WordPress 分类
      if (this.siteId.length > 0) {
        await this.loadCategories(this.siteId)
      }

      // 加载版本历史
      await this.loadVersions()
    }
  }

  async loadCategories(siteId: string): Promise<void> {
    const site = this.sites.find((s: WordPressSite) => s.id === siteId)
    if (!site) return
    const result = await WordPressApi.getCategories(site)
    if (result.success) {
      this.wpCategories = result.categories
    }
  }

  async loadVersions(): Promise<void> {
    if (this.articleId.length > 0) {
      this.versions = await VersionDao.findByArticleId(this.articleId)
    }
  }

  private applyTemplateState(templateName: string): void {
    this.templateName = templateName
    if (templateName.length === 0) {
      this.selectedTemplateId = ''
      return
    }

    const selectedTemplate = this.templates.find((template: ArticleTemplate) => template.name === templateName)
    this.selectedTemplateId = selectedTemplate ? selectedTemplate.id : ''
  }

  private sortAiSettingsList(settingsList: AISettingsModel[]): AISettingsModel[] {
    return [...settingsList].sort((left: AISettingsModel, right: AISettingsModel) => {
      if (left.isDefault !== right.isDefault) {
        return left.isDefault ? -1 : 1
      }
      return right.updatedAt.localeCompare(left.updatedAt)
    })
  }

  private getEffectiveAiSettings(): AISettingsModel | undefined {
    const selectedSetting = this.selectedAiSettingsId.length > 0
      ? this.aiSettingsList.find((s: AISettingsModel) => s.id === this.selectedAiSettingsId)
      : undefined

    return selectedSetting
      || this.aiSettingsList.find((s: AISettingsModel) => s.isDefault)
      || this.aiSettingsList[0]
  }

  private syncSelectedAiSettingsId(): void {
    const effectiveSetting = this.getEffectiveAiSettings()
    this.selectedAiSettingsId = effectiveSetting ? effectiveSetting.id : ''
  }

  private clearGenerateProgressTimer(): void {
    if (this.generateProgressTimer !== null) {
      clearInterval(this.generateProgressTimer)
      this.generateProgressTimer = null
    }
  }

  private clearGeneratingAutoScrollTimer(): void {
    if (this.generatingAutoScrollTimer !== null) {
      clearTimeout(this.generatingAutoScrollTimer)
      this.generatingAutoScrollTimer = null
    }
  }

  private scheduleAutoScrollToBottom(): void {
    if (!this.generating || !this.followGeneratingTail) return
    if (this.generatingAutoScrollTimer !== null) return
    this.generatingAutoScrollTimer = setTimeout(() => {
      this.generatingAutoScrollTimer = null
      if (!this.generating || !this.followGeneratingTail) return
      try {
        this.generatingContentScroller.scrollEdge(Edge.Bottom)
      } catch (scrollErr) {
        Logger.debug('ArticleEditorPage.scheduleAutoScrollToBottom skipped: %{public}s', String(scrollErr))
      }
    }, 80)
  }

  private cleanupGenerationState(progress: number): void {
    this.clearGenerateProgressTimer()
    this.clearGeneratingAutoScrollTimer()
    this.generating = false
    this.generateProgress = progress
    this.streamRequest = null
  }

  private buildArticleRecord(status: string = this.articleStatus): Article {
    const article = new Article()
    article.id = this.articleId
    article.userId = this.currentUserId
    article.siteId = this.siteId
    article.title = this.title
    article.content = this.content
    article.keywords = this.keywords
    article.template = this.templateName
    article.status = status.length > 0 ? status : 'draft'
    article.wordpressPostId = this.wordpressPostId
    article.wordCount = ContentMetrics.countWords(article.content)
    article.tokensUsed = this.articleTokensUsed
    return article
  }

  private normalizeChatEndpoint(endpoint: string): string {
    if (endpoint.includes('/chat/completions') || endpoint.includes('/v1/')) {
      return endpoint
    }
    return endpoint.replace(/\/$/, '') + '/chat/completions'
  }

  private validatePublishSite(): WordPressSite | null {
    if (this.title.length === 0 || this.content.length === 0) {
      UiFeedback.showToast({ message: '请填写标题和内容' })
      return null
    }
    if (this.siteId.length === 0) {
      UiFeedback.showToast({ message: '请选择发布站点' })
      this.activePanel = 'publish'
      return null
    }

    const site = this.sites.find((item: WordPressSite) => item.id === this.siteId)
    if (!site) {
      UiFeedback.showToast({ message: '站点不存在' })
      return null
    }
    return site
  }

  private getPublishCategories(): number[] | undefined {
    return this.selectedCategories.length > 0 ? [...this.selectedCategories] : undefined
  }

  private getPublishSlug(): string | undefined {
    const slug = this.postSlug.trim()
    this.postSlug = slug
    return slug.length > 0 ? slug : undefined
  }

  private async syncPublishedArticle(postId: string): Promise<boolean> {
    if (this.articleId.length === 0) {
      UiFeedback.showToast({ message: '本地文章不存在，请先保存后再试' })
      return false
    }

    const previousPostId = this.wordpressPostId
    const previousStatus = this.articleStatus

    try {
      this.wordpressPostId = postId
      this.articleStatus = 'published'
      const article = this.buildArticleRecord('published')
      await ArticleDao.update(article)
      const savedArticle = await ArticleDao.findById(this.articleId)
      if (savedArticle) {
        this.siteId = savedArticle.siteId
        this.wordpressPostId = savedArticle.wordpressPostId
        this.articleStatus = savedArticle.status.length > 0 ? savedArticle.status : 'draft'
      }
      return true
    } catch (err) {
      this.wordpressPostId = previousPostId
      this.articleStatus = previousStatus
      Logger.error('Sync published article failed: %{public}s', String(err))
      return false
    }
  }

  private async handleUpdatePublish(site: WordPressSite): Promise<void> {
    const result = await WordPressApi.updatePost(
      site,
      this.wordpressPostId,
      this.title,
      this.content,
      this.getPublishCategories(),
      this.getPublishSlug()
    )
    if (!result.success) {
      UiFeedback.showToast({ message: result.message })
      return
    }

    const synced = await this.syncPublishedArticle(this.wordpressPostId)
    if (!synced) {
      UiFeedback.showToast({ message: 'WordPress 已更新，但本地状态同步失败' })
      return
    }

    UiFeedback.showToast({ message: '更新发布成功' })
    const currentRefresh = AppStorage.get<number>(AppStorageKeys.ARTICLES_NEED_REFRESH) ?? 0
    AppStorage.setOrCreate<number>(AppStorageKeys.ARTICLES_NEED_REFRESH, currentRefresh + 1)
    this.navPathStack.pop()
  }

  private async handleFirstPublish(site: WordPressSite): Promise<void> {
    const result = await WordPressApi.publishPost(
      site,
      this.title,
      this.content,
      this.getPublishCategories(),
      this.getPublishSlug()
    )
    if (!result.success) {
      UiFeedback.showToast({ message: result.message })
      return
    }
    if (result.postId.length === 0) {
      UiFeedback.showToast({ message: '发布成功但未返回文章 ID，请稍后重试' })
      return
    }

    const synced = await this.syncPublishedArticle(result.postId)
    if (!synced) {
      UiFeedback.showToast({ message: 'WordPress 已发布，但本地状态同步失败' })
      return
    }

    UiFeedback.showToast({ message: '发布成功' })
    const currentRefresh2 = AppStorage.get<number>(AppStorageKeys.ARTICLES_NEED_REFRESH) ?? 0
    AppStorage.setOrCreate<number>(AppStorageKeys.ARTICLES_NEED_REFRESH, currentRefresh2 + 1)
    this.navPathStack.pop()
  }

  // 保存文章
  async handleSave(): Promise<boolean> {
    if (this.title.length === 0) {
      UiFeedback.showToast({ message: '请输入标题' })
      return false
    }

    this.saving = true
    try {
      if (this.isNew) {
        const article = await ArticleDao.insert(this.currentUserId, this.title, this.siteId,
          this.content, this.keywords, this.templateName, this.wordpressPostId, this.articleStatus)
        this.articleId = article.id
        this.isNew = false
        const updated = this.buildArticleRecord(article.status)
        await ArticleDao.update(updated)
        this.articleStatus = updated.status
        UiFeedback.showToast({ message: '文章创建成功' })
        const currentRefresh = AppStorage.get<number>(AppStorageKeys.ARTICLES_NEED_REFRESH) ?? 0
        AppStorage.setOrCreate<number>(AppStorageKeys.ARTICLES_NEED_REFRESH, currentRefresh + 1)
      } else {
        // 创建版本
        const versionNumber = await VersionDao.getNextVersionNumber(this.articleId)
        await VersionDao.insert(this.articleId, this.currentUserId, this.siteId, this.title,
          this.content, this.keywords, this.templateName, this.wordpressPostId, this.articleStatus, versionNumber)
        // 更新文章
        const article = this.buildArticleRecord()
        await ArticleDao.update(article)
        this.articleStatus = article.status
        await this.loadVersions()
        UiFeedback.showToast({ message: '已保存，已创建版本历史' })
        const currentRefresh = AppStorage.get<number>(AppStorageKeys.ARTICLES_NEED_REFRESH) ?? 0
        AppStorage.setOrCreate<number>(AppStorageKeys.ARTICLES_NEED_REFRESH, currentRefresh + 1)
      }
      return true
    } catch (err) {
      Logger.error('Save article failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '保存失败' })
      return false
    } finally {
      this.saving = false
    }
  }

  // AI 生成文章
  handleGenerate(): void {
    if (this.keywords.length === 0) {
      UiFeedback.showToast({ message: '请输入关键词' })
      return
    }

    const aiSettings = this.getEffectiveAiSettings()
    if (!aiSettings) {
      UiFeedback.showToast({ message: '请先在 AI 设置中创建配置' })
      return
    }
    this.selectedAiSettingsId = aiSettings.id
    if (aiSettings.apiKey.length === 0) {
      UiFeedback.showToast({ message: '请先配置 API Key' })
      return
    }
    if (aiSettings.apiEndpoint.length === 0) {
      UiFeedback.showToast({ message: '请先配置 API 端点' })
      return
    }

    // 构建提示词
    const selectedTemplate = this.templates.find((t: ArticleTemplate) => t.id === this.selectedTemplateId)
    let systemPrompt = selectedTemplate ? selectedTemplate.systemPrompt : aiSettings.systemPrompt
    systemPrompt = systemPrompt
      .replace(/\{keywords\}/g, this.keywords)
      .replace(/\{template\}/g, this.templateName.length > 0 ? this.templateName : '默认模板')

    const userMessage = `关键词：${this.keywords}\n模板风格：${this.templateName.length > 0 ? this.templateName : '默认模板'}\n\n请直接输出文章内容：`

    const systemMsg = new ChatMessage()
    systemMsg.role = 'system'
    systemMsg.content = systemPrompt

    const userMsg = new ChatMessage()
    userMsg.role = 'user'
    userMsg.content = userMessage

    this.generating = true
    this.generateProgress = 0
    this.followGeneratingTail = true
    this.content = ''
    this.isPreviewOpen = false
    this.activeGenerationId += 1
    const generationId = this.activeGenerationId

    // 进度模拟
    this.clearGenerateProgressTimer()
    this.generateProgressTimer = setInterval(() => {
      if (this.generateProgress < 90) {
        this.generateProgress = Math.min(90, this.generateProgress + Math.random() * 15)
      }
    }, 1000)

    const options = new StreamOptions()
    options.endpoint = this.normalizeChatEndpoint(aiSettings.apiEndpoint)
    options.apiKey = aiSettings.apiKey
    options.model = aiSettings.model
    options.messages = [systemMsg, userMsg]
    this.lastGenerationTokens = 0
    options.onUpdate = (content: string) => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.content = content
      this.scheduleAutoScrollToBottom()
    }
    options.onUsage = (totalTokens: number) => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.lastGenerationTokens = totalTokens
    }
    options.onComplete = () => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.cleanupGenerationState(100)
      if (this.lastGenerationTokens <= 0) {
        this.lastGenerationTokens = ContentMetrics.estimateTokens(systemPrompt + '\n' + userMessage) + ContentMetrics.estimateTokens(this.content)
      }
      this.articleTokensUsed += this.lastGenerationTokens
      if (this.selectedAiSettingsId.length > 0) {
        AISettingsDao.addTokensUsed(this.selectedAiSettingsId, this.lastGenerationTokens).then(() => {
          const idx = this.aiSettingsList.findIndex((s: AISettingsModel) => s.id === this.selectedAiSettingsId)
          if (idx >= 0) {
            const updated = this.aiSettingsList[idx]
            updated.tokensUsed += this.lastGenerationTokens
            this.aiSettingsList = [...this.aiSettingsList]
          }
        }).catch((err: Error) => {
          Logger.warn('Add tokens used failed: %{public}s', String(err))
        })
      }
      UiFeedback.showToast({ message: '文章生成完成' })

      // 标记主题为已使用
      if (this.selectedTopicId.length > 0) {
        TopicDao.markUsed(this.selectedTopicId).then(() => {
          this.selectedTopicId = ''
          TopicDao.findByUserId(this.currentUserId, 0).then((topics: Topic[]) => {
            this.topics = topics
          })
        })
      }
    }
    options.onError = (err: string) => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.cleanupGenerationState(0)
      UiFeedback.showToast({ message: `生成失败: ${err}` })
    }

    try {
      this.streamRequest = AIStreamClient.sendStream(options)
    } catch (err) {
      if (generationId === this.activeGenerationId) {
        this.cleanupGenerationState(0)
      }
      UiFeedback.showToast({ message: `生成失败: ${String(err)}` })
    }
  }

  // 停止 AI 生成
  handleStopGenerate(): void {
    if (this.streamRequest) {
      AIStreamClient.abortStream(this.streamRequest)
    }
    this.activeGenerationId += 1
    this.cleanupGenerationState(0)
    UiFeedback.showToast({ message: '已停止生成' })
  }

  // 发布到 WordPress
  async handlePublish(): Promise<void> {
    const site = this.validatePublishSite()
    if (!site) {
      return
    }

    const saved = await this.handleSave()
    if (!saved) {
      return
    }

    this.publishing = true
    try {
      if (this.wordpressPostId.length > 0) {
        await this.handleUpdatePublish(site)
      } else {
        await this.handleFirstPublish(site)
      }
    } catch (err) {
      Logger.error('Publish failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '发布失败' })
    } finally {
      this.publishing = false
    }
  }

  // 生成 SEO Slug
  async handleGenerateSlug(): Promise<void> {
    if (this.title.length === 0) {
      UiFeedback.showToast({ message: '请先输入标题' })
      return
    }
    const aiSettings = this.getEffectiveAiSettings()
    if (!aiSettings) {
      UiFeedback.showToast({ message: '请先在 AI 设置中创建配置' })
      return
    }
    this.selectedAiSettingsId = aiSettings.id
    if (aiSettings.apiEndpoint.length === 0 || aiSettings.apiKey.length === 0) {
      UiFeedback.showToast({ message: '请先在 AI 设置中配置 API' })
      return
    }
    if (!aiSettings.slugEnabled) {
      UiFeedback.showToast({ message: '文章别名生成功能已禁用，请在 AI 设置中启用' })
      return
    }
    this.generatingSlug = true
    try {
      const slug = await AIStreamClient.generateSlug(
        this.title,
        this.normalizeChatEndpoint(aiSettings.apiEndpoint),
        aiSettings.apiKey,
        aiSettings.slugModel.length > 0 ? aiSettings.slugModel : aiSettings.model
      )
      this.postSlug = slug
      UiFeedback.showToast({ message: '已生成 SEO 别名' })
    } catch (err) {
      Logger.error('Generate slug failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '生成别名失败' })
    }
    this.generatingSlug = false
  }

  // 打开图片生成对话框
  private handleOpenImageDialog(): void {
    this.imagePrompt = ImageGenerationService.generateImagePrompt(this.keywords, this.title)
    this.imageStatus = ''
    this.showImageDialog = true
  }

  // 生成图片
  private async handleGenerateImage(): Promise<void> {
    if (this.imageApiKey.length === 0) {
      UiFeedback.showToast({ message: '请先配置图片生成 API Key' })
      return
    }
    if (this.imagePrompt.length === 0) {
      UiFeedback.showToast({ message: '请输入图片描述' })
      return
    }
    this.generatingImage = true
    this.imageStatus = '准备生成...'
    try {
      let config = new ImageGenerationConfig()
      config.provider = this.imageProvider
      config.apiKey = this.imageApiKey
      config.apiEndpoint = this.imageEndpoint
      config.model = this.imageModel
      const result: GeneratedImage = await ImageGenerationService.generateImage(
        this.imagePrompt, config, (status: string) => { this.imageStatus = status })
      this.content = ImageGenerationService.insertImageToContent(this.content, result.url, result.alt)
      UiFeedback.showToast({ message: '配图已插入文章' })
      this.showImageDialog = false
    } catch (err) {
      this.imageStatus = '生成失败: ' + String(err)
      UiFeedback.showToast({ message: '图片生成失败' })
    } finally {
      this.generatingImage = false
    }
  }

  // 选择主题
  handleSelectTopic(topic: Topic): void {
    this.selectedTopicId = topic.id
    if (topic.keywords.length > 0) {
      this.keywords = topic.keywords
    }
    if (topic.title.length > 0) {
      this.title = topic.title
    }
    UiFeedback.showToast({ message: `已选择主题: ${topic.title}` })
  }

  // 恢复版本
  handleRestoreVersion(version: ArticleVersion): void {
    if (this.streamRequest) {
      AIStreamClient.abortStream(this.streamRequest)
    }
    this.activeGenerationId += 1
    this.cleanupGenerationState(0)

    this.selectedTopicId = ''
    this.title = version.title
    this.content = version.content
    this.keywords = version.keywords
    this.applyTemplateState(version.template)
    this.siteId = version.siteId
    this.wordpressPostId = version.wordpressPostId
    this.articleStatus = version.status.length > 0 ? version.status : 'draft'
    UiFeedback.showToast({ message: `已恢复到版本 ${version.versionNumber}` })
  }

  // 处理导出文章
  private async handleExport(format: 'markdown' | 'txt' | 'html'): Promise<void> {
    if (this.title.length === 0 && this.content.length === 0) {
      UiFeedback.showToast({ message: '文章标题和内容为空，无法导出' })
      return
    }

    let content: string
    let extension: string

    switch (format) {
      case 'markdown':
        content = ArticleExportHelper.toMarkdown(
          this.title,
          this.keywords,
          this.templateName,
          this.articleStatus,
          this.content
        )
        extension = 'md'
        break
      case 'txt':
        content = ArticleExportHelper.toPlainText(
          this.title,
          this.keywords,
          this.templateName,
          this.articleStatus,
          this.content
        )
        extension = 'txt'
        break
      case 'html':
        content = ArticleExportHelper.toHtml(
          this.title,
          this.keywords,
          this.templateName,
          this.articleStatus,
          this.content,
          this.getEffectiveTheme() === 'dark'
        )
        extension = 'html'
        break
      default:
        return
    }

    // 清理文件名中的特殊字符
    const safeTitle = (this.title || '无标题').replace(/[<>:"/\\|?*]/g, '_')
    const fileName = `${safeTitle}.${extension}`

    let file: fs.File | null = null
    try {
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]

      const documentPicker = new picker.DocumentViewPicker()
      const result = await documentPicker.save(documentSaveOptions)

      if (result === null || result === undefined || result.length === 0) {
        return
      }

      const uri = result[0]
      file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY | fs.OpenMode.CREATE)
      fs.writeSync(file.fd, content)

      UiFeedback.showToast({ message: '文章已导出' })
    } catch (err) {
      Logger.error('Failed to export article: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file.fd)
        } catch (closeErr) {
          Logger.error('Failed to close file: %{public}s', String(closeErr))
        }
      }
    }
  }

  // 切换版本展开状态
  private toggleVersionExpand(versionId: string): void {
    const index = this.expandedVersionIds.indexOf(versionId)
    if (index >= 0) {
      this.expandedVersionIds = this.expandedVersionIds.filter((id: string) => id !== versionId)
    } else {
      this.expandedVersionIds = [...this.expandedVersionIds, versionId]
    }
  }

  // 删除版本
  private async handleDeleteVersion(version: ArticleVersion): Promise<void> {
    try {
      await VersionDao.deleteById(version.id)
      // 重新加载版本列表
      await this.loadVersions()
      UiFeedback.showToast({ message: `版本 ${version.versionNumber} 已删除` })
    } catch (err) {
      Logger.error('Failed to delete version: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除版本失败' })
    }
  }

  // 获取内容长度（字数统计）
  private getContentLength(content: string): number {
    return ContentMetrics.countWords(content)
  }

  private previewWebController: webview.WebviewController = new webview.WebviewController()
  private readonly previewBaseUrl: string = 'resource://rawfile/preview/preview.html'

  private openPreviewSheet(): void {
    if (this.editorMode !== 'markdown') return
    const theme = this.getEffectiveTheme()
    this.previewUrl = `${this.previewBaseUrl}?t=${Date.now()}&theme=${theme}`
    this.isPreviewOpen = true
  }

  private closePreviewSheet(): void {
    this.isPreviewOpen = false
  }

  private getEffectiveTheme(): string {
    if (this.themeMode === ThemeMode.Dark) return 'dark'
    if (this.themeMode === ThemeMode.Light) return 'light'
    return this.systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? 'dark' : 'light'
  }

  private onThemeChanged(): void {
    this.syncPreviewToWeb()
  }

  private getPreviewMarkdownArg(markdown: string): string {
    let json = JSON.stringify(markdown)
    json = json.replace(/<\/script/gi, '<\\/script')
    return json
  }

  private syncPreviewToWeb(): void {
    if (!this.isPreviewOpen) return
    const arg = this.getPreviewMarkdownArg(this.content)
    const theme = this.getEffectiveTheme()
    const themeScript = `window.__setTheme && window.__setTheme('${theme}');`
    const script = `window.__setMarkdown && window.__setMarkdown(${arg});`
    try {
      this.previewWebController.runJavaScript(themeScript)
      this.previewWebController.runJavaScript(script)
    } catch (syncErr) {
      Logger.debug('ArticleEditorPage.syncPreviewToWeb skipped: %{public}s', String(syncErr))
    }
  }

  @Builder
  private buildPreviewSheet(): void {
    ArticlePreviewSheetComponent({
      previewUrl: this.previewUrl,
      controller: this.previewWebController,
      onPageReady: () => {
        this.syncPreviewToWeb()
      }
    })
  }

  // 插入 Markdown 格式
  private insertMarkdown(prefix: string, suffix: string, placeholder: string): void {
    this.content = this.content + prefix + placeholder + suffix
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部工具栏
        this.ToolbarArea()

        Scroll() {
          Column() {
            // 标题输入
            this.TitleSection()

            // 关键词输入
            this.KeywordsSection()

            // 内容编辑区
            this.ContentSection()

            // 功能面板切换
            ArticleEditorPanelTabsComponent({
              activePanel: this.activePanel,
              versionsCount: this.versions.length,
              onChange: (panelKey: string) => {
                this.activePanel = panelKey
              }
            })

            // 站点快速选择（始终显示）
            ArticleSiteQuickSelectComponent({
              sites: this.sites,
              selectedSiteId: this.siteId,
              onSelectSite: (site: WordPressSite) => {
                this.siteId = site.id
                this.selectedCategories = []
                this.loadCategories(this.siteId)
              }
            })

            // 当前面板内容
            if (this.activePanel === 'ai') {
              this.AIPanel()
            } else if (this.activePanel === 'publish') {
              ArticlePublishPanelComponent({
                categories: this.wpCategories,
                selectedCategories: this.selectedCategories,
                postSlug: $postSlug,
                generatingSlug: this.generatingSlug,
                wordpressPostId: this.wordpressPostId,
                onToggleCategory: (categoryId: number) => {
                  this.toggleCategory(categoryId)
                },
                onGenerateSlug: () => {
                  this.handleGenerateSlug()
                }
              })
            } else if (this.activePanel === 'version') {
              ArticleVersionPanelComponent({
                versions: this.versions,
                expandedVersionIds: this.expandedVersionIds,
                onToggleExpand: (versionId: string) => {
                  this.toggleVersionExpand(versionId)
                },
                onDelete: (version: ArticleVersion) => {
                  this.handleDeleteVersion(version)
                },
                onRestore: (version: ArticleVersion) => {
                  this.handleRestoreVersion(version)
                }
              })
            }

            // 图片生成面板（显示在 AI 面板下方）
            if (this.showImageDialog) {
              this.ImageGenerationPanel()
            }
          }
          .width('100%')
          .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ResourceColors.BG_SECONDARY)
      .bindSheet($$this.isPreviewOpen, this.buildPreviewSheet(), {
        height: SheetSize.LARGE,
        onDisappear: () => {
          this.previewUrl = ''
        }
      })
    }
    .hideTitleBar(true)
  }

  // 顶部工具栏
  @Builder
  ToolbarArea() {
    Row() {
      Text(this.isNew ? '新建文章' : '编辑文章')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.SM }) {
        // 导出按钮
        Button('导出')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .enabled(this.title.length > 0 || this.content.length > 0)
          .bindMenu([
            { value: '导出为 Markdown (.md)', action: () => { this.handleExport('markdown') } },
            { value: '导出为纯文本 (.txt)', action: () => { this.handleExport('txt') } },
            { value: '导出为 HTML (.html)', action: () => { this.handleExport('html') } }
          ])

        // 保存
        Button(this.saving ? '保存中...' : '保存')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .enabled(!this.saving && !this.generating)
          .onClick(() => {
            this.handleSave()
          })

        // 发布
        Button(this.publishing ? '发布中...' : (this.wordpressPostId.length > 0 ? '更新' : '发布'))
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .backgroundColor(this.publishing ? ResourceColors.PRIMARY_DISABLED : ResourceColors.PRIMARY)
          .borderRadius(Radius.SM)
          .height(36)
          .padding({ left: Spacing.MD, right: Spacing.MD })
          .enabled(!this.publishing && !this.generating)
          .onClick(() => {
            this.handlePublish()
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: Spacing.SM, right: Spacing.BASE })
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .border({ width: { bottom: 0.5 }, color: ResourceColors.DIVIDER })
  }

  // 标题输入
  @Builder
  TitleSection() {
    TextInput({ text: this.title, placeholder: '输入文章标题...' })
      .fontSize(Typography.TITLE)
      .fontColor(ResourceColors.TEXT_PRIMARY)
      .placeholderColor(ResourceColors.TEXT_HINT)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(Color.Transparent)
      .padding({ top: Spacing.BASE, bottom: Spacing.SM })
      .onChange((value: string) => {
        this.title = value
      })
  }

  // 关键词输入
  @Builder
  KeywordsSection() {
    Column({ space: Spacing.XS }) {
      Text('关键词')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)

      TextInput({ text: this.keywords, placeholder: '输入关键词，用逗号分隔' })
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .placeholderColor(ResourceColors.TEXT_HINT)
        .height(ComponentSize.INPUT_HEIGHT)
        .backgroundColor(ResourceColors.BG_PRIMARY)
        .borderRadius(Radius.SM)
        .onChange((value: string) => {
          this.keywords = value
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: Spacing.SM })
  }

  // 内容编辑区
  @Builder
  ContentSection() {
    Column({ space: Spacing.XS }) {
      // 顶部工具栏行
      Row() {
        Text('内容')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        Blank()

        // 编辑器模式切换
        Row({ space: Spacing.XS }) {
          Text('Markdown')
            .fontSize(Typography.CAPTION)
            .fontColor(this.editorMode === 'markdown' ? ResourceColors.PRIMARY : ResourceColors.TEXT_SECONDARY)
            .fontWeight(this.editorMode === 'markdown' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .backgroundColor(this.editorMode === 'markdown' ? 'rgba(0,125,255,0.1)' : Color.Transparent)
            .borderRadius(Radius.SM)
            .onClick(() => { this.editorMode = 'markdown' })

          Text('纯文本')
            .fontSize(Typography.CAPTION)
            .fontColor(this.editorMode === 'plain' ? ResourceColors.PRIMARY : ResourceColors.TEXT_SECONDARY)
            .fontWeight(this.editorMode === 'plain' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .backgroundColor(this.editorMode === 'plain' ? 'rgba(0,125,255,0.1)' : Color.Transparent)
            .borderRadius(Radius.SM)
            .onClick(() => {
              this.editorMode = 'plain'
            })
        }

        // 分隔线
        Divider()
          .vertical(true)
          .height(20)
          .strokeWidth(1)
          .color(ResourceColors.DIVIDER)
          .margin({ left: Spacing.SM, right: Spacing.SM })

        // 预览按钮（仅 Markdown 模式显示）
        if (this.editorMode === 'markdown') {
          Text('预览')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .backgroundColor('rgba(0,125,255,0.1)')
            .borderRadius(Radius.SM)
            .onClick(() => {
              this.openPreviewSheet()
            })
        }

        // 生成状态指示
        if (this.generating) {
          Row({ space: Spacing.XS }) {
            LoadingProgress()
              .width(14)
              .height(14)
              .color(ResourceColors.PRIMARY)
            Text(`${Math.floor(this.generateProgress)}%`)
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.PRIMARY)
          }
          .margin({ left: Spacing.SM })

          if (!this.followGeneratingTail) {
            Text('跟随底部')
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.PRIMARY)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
              .backgroundColor('rgba(0,125,255,0.1)')
              .borderRadius(Radius.SM)
              .margin({ left: Spacing.SM })
              .onClick(() => {
                this.followGeneratingTail = true
                this.scheduleAutoScrollToBottom()
              })
          }
        }
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      // Markdown 工具栏（仅在 Markdown 编辑模式下显示）
      if (this.editorMode === 'markdown') {
        ArticleEditorFormatToolbarComponent({
          onInsertMarkdown: (prefix: string, suffix: string, placeholder: string) => {
            this.insertMarkdown(prefix, suffix, placeholder)
          }
        })
      }

      if (this.generating) {
        Scroll(this.generatingContentScroller) {
          Text(this.content.length > 0 ? this.content : '正在生成内容...')
            .fontSize(Typography.BODY)
            .fontColor(this.content.length > 0 ? ResourceColors.TEXT_PRIMARY : ResourceColors.TEXT_HINT)
            .width('100%')
        }
        .width('100%')
        .height(300)
        .backgroundColor(ResourceColors.BG_PRIMARY)
        .borderRadius(Radius.SM)
        .padding(Spacing.MD)
        .scrollBar(BarState.Auto)
        .onWillScroll((_xOffset: number, _yOffset: number, _scrollState: ScrollState, scrollSource: ScrollSource) => {
          if (scrollSource === ScrollSource.DRAG
            || scrollSource === ScrollSource.OTHER_USER_INPUT
            || scrollSource === ScrollSource.SCROLL_BAR
            || scrollSource === ScrollSource.SCROLL_BAR_FLING) {
            this.followGeneratingTail = false
          }
        })
        .onAppear(() => {
          this.scheduleAutoScrollToBottom()
        })
      } else {
        TextArea({ text: this.content, placeholder: this.editorMode === 'markdown' ? '输入 Markdown 内容...' : '输入文章内容...' })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .width('100%')
          .height(300)
          .backgroundColor(ResourceColors.BG_PRIMARY)
          .borderRadius(Radius.SM)
          .padding(Spacing.MD)
          .onChange((value: string) => {
            this.content = value
          })
      }

      Row({ space: Spacing.MD }) {
        Text(`字数：${this.getContentLength(this.content)}`)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_HINT)
        if (this.lastGenerationTokens > 0) {
          Text(`本次 Token：${this.lastGenerationTokens}`)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_HINT)
        }
        if (this.articleTokensUsed > 0) {
          Text(`累计 Token：${this.articleTokensUsed}`)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_HINT)
        }
        Blank()
      }
      .width('100%')
      .padding({ top: 2 })
    }
    .width('100%')
    .padding({ top: Spacing.BASE })
  }

  // AI 生成面板
  @Builder
  AIPanel() {
    Column({ space: Spacing.MD }) {
      // AI 配置选择
      if (this.aiSettingsList.length > 0) {
        Column({ space: Spacing.XS }) {
          Text('AI 配置')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Select(this.aiSettingsList.map((s: AISettingsModel) => {
            const option: SelectOption = { value: s.name }
            return option
          }))
            .selected(this.getSelectedAiSettingsIndex())
            .value(this.getSelectedAiSettingsName())
            .onSelect((index: number) => {
              if (index >= 0 && index < this.aiSettingsList.length) {
                this.selectedAiSettingsId = this.aiSettingsList[index].id
              }
            })
            .width('100%')
            .height(ComponentSize.INPUT_HEIGHT)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .selectedOptionFont({ size: Typography.BODY, weight: FontWeight.Normal })
            .optionFont({ size: Typography.BODY, weight: FontWeight.Normal })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 模板选择
      if (this.templates.length > 0) {
        Column({ space: Spacing.XS }) {
          Text('文章模板')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Select(this.templates.map((t: ArticleTemplate) => {
            const option: SelectOption = { value: t.name }
            return option
          }))
            .selected(this.templates.findIndex((t: ArticleTemplate) => t.id === this.selectedTemplateId))
            .value(this.getSelectedTemplateName())
            .onSelect((index: number) => {
              if (index >= 0 && index < this.templates.length) {
                this.selectedTemplateId = this.templates[index].id
                this.templateName = this.templates[index].name
              }
            })
            .width('100%')
            .height(ComponentSize.INPUT_HEIGHT)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .selectedOptionFont({ size: Typography.BODY, weight: FontWeight.Normal })
            .optionFont({ size: Typography.BODY, weight: FontWeight.Normal })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 主题快选
      if (this.topics.length > 0) {
        Column({ space: Spacing.XS }) {
          Text('可用主题')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Select(this.topics.map((t: Topic) => {
            const option: SelectOption = { value: t.title }
            return option
          }))
            .selected(this.topics.findIndex((t: Topic) => t.id === this.selectedTopicId))
            .value(this.getSelectedTopicName())
            .onSelect((index: number) => {
              if (index >= 0 && index < this.topics.length) {
                this.handleSelectTopic(this.topics[index])
              }
            })
            .width('100%')
            .height(ComponentSize.INPUT_HEIGHT)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .selectedOptionFont({ size: Typography.BODY, weight: FontWeight.Normal })
            .optionFont({ size: Typography.BODY, weight: FontWeight.Normal })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 生成按钮
      if (this.generating) {
        Column({ space: Spacing.SM }) {
          Progress({ value: this.generateProgress, total: 100, type: ProgressType.Linear })
            .width('100%')
            .color(ResourceColors.PRIMARY)

          Button('停止生成')
            .type(ButtonType.Normal)
            .width('100%')
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.ERROR)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(ResourceColors.ERROR)
            .borderRadius(Radius.SM)
            .onClick(() => {
              this.handleStopGenerate()
            })
        }
        .width('100%')
      } else {
        Button('AI 生成文章')
          .type(ButtonType.Normal)
          .width('100%')
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .backgroundColor(ResourceColors.PRIMARY)
          .borderRadius(Radius.SM)
          .enabled(this.keywords.length > 0 && this.aiSettingsList.length > 0)
          .onClick(() => {
            this.handleGenerate()
          })
      }

      // 生成配图按钮
      Button('生成配图')
        .type(ButtonType.Normal)
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .fontSize(Typography.BODY_LARGE)
        .fontColor(ResourceColors.PRIMARY)
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor(ResourceColors.PRIMARY)
        .borderRadius(Radius.SM)
        .enabled(!this.generatingImage && !this.generating)
        .onClick(() => { this.handleOpenImageDialog() })
    }
    .width('100%')
    .padding({ top: Spacing.BASE })
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }

  // 图片生成面板
  @Builder
  ImageGenerationPanel() {
    Column({ space: Spacing.MD }) {
      // 标题行
      Row() {
        Text('生成配图')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)

        Blank()

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_SECONDARY])
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showImageDialog = false
        })
      }
      .width('100%')

      // 图片描述输入
      Column({ space: Spacing.XS }) {
        Text('图片描述')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        TextArea({ text: this.imagePrompt, placeholder: '输入图片描述...' })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .width('100%')
          .height(80)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .padding(Spacing.MD)
          .onChange((value: string) => {
            this.imagePrompt = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 服务提供商选择
      Column({ space: Spacing.XS }) {
        Text('服务提供商')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        Select(IMAGE_PROVIDERS.map((p: ImageProviderInfo) => {
          const option: SelectOption = { value: p.label }
          return option
        }))
          .selected(IMAGE_PROVIDERS.findIndex((p: ImageProviderInfo) => p.value === this.imageProvider))
          .value(this.getImageProviderLabel())
          .onSelect((index: number) => {
            if (index >= 0 && index < IMAGE_PROVIDERS.length) {
              this.imageProvider = IMAGE_PROVIDERS[index].value
              this.imageEndpoint = IMAGE_PROVIDERS[index].endpoint
              if (IMAGE_PROVIDERS[index].models.length > 0) {
                this.imageModel = IMAGE_PROVIDERS[index].models[0]
              }
            }
          })
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .fontColor(ResourceColors.TEXT_PRIMARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // API Key 输入
      Column({ space: Spacing.XS }) {
        Text('API Key')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        TextInput({ text: this.imageApiKey, placeholder: '输入 API Key' })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.imageApiKey = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 端点输入（可选）
      Column({ space: Spacing.XS }) {
        Text('API 端点（可选）')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        TextInput({ text: this.imageEndpoint, placeholder: '使用默认端点' })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onChange((value: string) => {
            this.imageEndpoint = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 模型输入（可选）
      Column({ space: Spacing.XS }) {
        Text('模型（可选）')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)

        TextInput({ text: this.imageModel, placeholder: '使用默认模型' })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onChange((value: string) => {
            this.imageModel = value
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 状态显示
      if (this.imageStatus.length > 0) {
        Text(this.imageStatus)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .width('100%')
      }

      // 按钮行
      Row({ space: Spacing.MD }) {
        Button('取消')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT)
          .onClick(() => {
            this.showImageDialog = false
          })

        if (this.generatingImage) {
          Button('生成中...')
            .type(ButtonType.Normal)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(ResourceColors.PRIMARY_DISABLED)
            .borderRadius(Radius.SM)
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .enabled(false)
        } else {
          Button('生成')
            .type(ButtonType.Normal)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(ResourceColors.PRIMARY)
            .borderRadius(Radius.SM)
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .onClick(() => {
              this.handleGenerateImage()
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }

  // 辅助方法
  getSelectedAiSettingsName(): string {
    const found = this.getEffectiveAiSettings()
    return found ? found.name : '选择 AI 配置'
  }

  // 获取当前图片提供商的标签
  private getImageProviderLabel(): string {
    const provider = IMAGE_PROVIDERS.find((p: ImageProviderInfo) => p.value === this.imageProvider)
    return provider ? provider.label : '选择提供商'
  }

  getSelectedAiSettingsIndex(): number {
    const found = this.getEffectiveAiSettings()
    return found ? this.aiSettingsList.findIndex((s: AISettingsModel) => s.id === found.id) : -1
  }

  getSelectedTemplateName(): string {
    const found = this.templates.find((t: ArticleTemplate) => t.id === this.selectedTemplateId)
    return found ? found.name : '选择模板'
  }

  getSelectedTopicName(): string {
    const found = this.topics.find((t: Topic) => t.id === this.selectedTopicId)
    return found ? found.title : '选择主题'
  }

  toggleCategory(catId: number): void {
    const index = this.selectedCategories.indexOf(catId)
    if (index >= 0) {
      this.selectedCategories = this.selectedCategories.filter((id: number) => id !== catId)
    } else {
      this.selectedCategories = [...this.selectedCategories, catId]
    }
  }
}
