// 文章编辑器页面 — P0 核心页面
// 功能: 标题/关键词/内容编辑、AI 流式生成、WordPress 发布、模板/主题选择、版本历史

import http from '@ohos.net.http'
import { picker } from '@kit.CoreFileKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { UiFeedback } from '../utils/UiFeedback'
import { Colors, Typography, Spacing, Radius, ComponentSize, AnimDuration } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
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
import { Logger } from '../utils/Logger'
import { formatDateTime } from '../utils/DateUtil'
import { ImageGenerationService, ImageGenerationConfig, GeneratedImage, IMAGE_PROVIDERS, ImageProviderInfo } from '../services/ai/ImageGenerationService'

@Component
export struct ArticleEditorPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

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

  // 版本历史
  @State versions: ArticleVersion[] = []
  @State showVersionSheet: boolean = false
  @State expandedVersionIds: string[] = []

  // AI 流请求引用
  private streamRequest: http.HttpRequest | null = null
  private generateProgressTimer: number | null = null
  private activeGenerationId: number = 0

  // 当前活跃面板
  @State activePanel: string = 'ai' // 'ai' | 'publish' | 'version'

  // 编辑器模式
  @State previewMode: boolean = false   // false=edit, true=preview
  @State editorMode: string = 'markdown'  // 'markdown' | 'plain'

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
    const params = this.navPathStack.getParamByName(Routes.ARTICLE_EDITOR) as Record<string, string>[]
    const param = params && params.length > 0 ? params[params.length - 1] : undefined
    const articleId = param && param['articleId'] ? param['articleId'] : 'new'
    const sourceType = param && param['sourceType'] ? param['sourceType'] : 'article'
    const sourceId = param && param['sourceId'] ? param['sourceId'] : ''
    const initialTitle = param && param['initialTitle'] ? param['initialTitle'] : ''
    const initialKeywords = param && param['initialKeywords'] ? param['initialKeywords'] : ''

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

  private cleanupGenerationState(progress: number): void {
    this.clearGenerateProgressTimer()
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
        this.articleStatus = article.status
        UiFeedback.showToast({ message: '文章创建成功' })
        const currentRefresh = AppStorage.get<number>('articlesNeedRefresh') ?? 0
        AppStorage.setOrCreate<number>('articlesNeedRefresh', currentRefresh + 1)
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
        const currentRefresh = AppStorage.get<number>('articlesNeedRefresh') ?? 0
        AppStorage.setOrCreate<number>('articlesNeedRefresh', currentRefresh + 1)
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
    this.content = ''
    this.previewMode = false  // 生成时切换到编辑模式
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
    options.onUpdate = (content: string) => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.content = content
    }
    options.onComplete = () => {
      if (generationId !== this.activeGenerationId) {
        return
      }
      this.cleanupGenerationState(100)
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
    this.showVersionSheet = false
    UiFeedback.showToast({ message: `已恢复到版本 ${version.versionNumber}` })
  }

  // 导出文章 - Markdown格式
  private exportToMarkdown(): string {
    return `# ${this.title || '无标题'}

**关键词:** ${this.keywords || '无'}
**模板:** ${this.templateName || '默认'}
**状态:** ${this.articleStatus || '草稿'}

---

${this.content || ''}
`
  }

  // 导出文章 - 纯文本格式（去除markdown标记）
  private exportToPlainText(): string {
    let text = this.content || ''
    // 移除标题标记
    text = text.replace(/^#{1,6}\s+/gm, '')
    // 移除粗体/斜体标记
    text = text.replace(/\*\*?|\*\*?/g, '')
    // 移除链接标记 [text](url) -> text
    text = text.replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')
    // 移除图片标记 ![alt](url)
    text = text.replace(/!\[([^\]]*)\]\([^\)]+\)/g, '')
    // 移除代码块标记
    text = text.replace(/```[\s\S]*?```/g, '')
    text = text.replace(/`([^`]+)`/g, '$1')
    // 移除水平分割线
    text = text.replace(/^---+$/gm, '')
    // 移除引用标记
    text = text.replace(/^>\s*/gm, '')
    // 移除列表标记
    text = text.replace(/^[\*\-\+]\s+/gm, '')
    text = text.replace(/^\d+\.\s+/gm, '')

    return `${this.title || '无标题'}
========================================

关键词: ${this.keywords || '无'}
模板: ${this.templateName || '默认'}
状态: ${this.articleStatus || '草稿'}

----------------------------------------

${text}
`
  }

  // 导出文章 - HTML格式（基础转换）
  private exportToHtml(): string {
    let htmlContent = this.content || ''
    // 转换标题
    htmlContent = htmlContent.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>')
    htmlContent = htmlContent.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>')
    htmlContent = htmlContent.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>')
    htmlContent = htmlContent.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
    htmlContent = htmlContent.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
    htmlContent = htmlContent.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>')
    // 转换粗体
    htmlContent = htmlContent.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    htmlContent = htmlContent.replace(/__(.+?)__/g, '<strong>$1</strong>')
    // 转换斜体
    htmlContent = htmlContent.replace(/\*(.+?)\*/g, '<em>$1</em>')
    htmlContent = htmlContent.replace(/_(.+?)_/g, '<em>$1</em>')
    // 转换链接
    htmlContent = htmlContent.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2">$1</a>')
    // 转换代码块
    htmlContent = htmlContent.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
    htmlContent = htmlContent.replace(/`([^`]+)`/g, '<code>$1</code>')
    // 转换段落（简单处理：将连续空行分隔的文本包裹在p标签中）
    const paragraphs = htmlContent.split(/\n\n+/)
    htmlContent = paragraphs.map((p: string) => {
      const trimmed = p.trim()
      if (trimmed.length === 0) return ''
      if (trimmed.startsWith('<h') || trimmed.startsWith('<pre')) return trimmed
      return `<p>${trimmed.replace(/\n/g, '<br>')}</p>`
    }).join('\n')

    return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${this.title || '无标题'}</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; color: #333; }
        h1 { border-bottom: 2px solid #333; padding-bottom: 10px; }
        h2, h3, h4, h5, h6 { margin-top: 24px; margin-bottom: 16px; }
        .meta { color: #666; font-size: 0.9em; margin-bottom: 20px; padding: 10px; background: #f5f5f5; border-radius: 4px; }
        pre { background: #f4f4f4; padding: 16px; overflow-x: auto; border-radius: 4px; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
        a { color: #0366d6; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>${this.title || '无标题'}</h1>
    <div class="meta">
        <p>关键词: ${this.keywords || '无'} | 模板: ${this.templateName || '默认'} | 状态: ${this.articleStatus || '草稿'}</p>
    </div>
    <hr>
    <div class="content">
${htmlContent}
    </div>
</body>
</html>`
  }

  // 处理导出文章
  private async handleExport(format: 'markdown' | 'txt' | 'html'): Promise<void> {
    if (this.title.length === 0 && this.content.length === 0) {
      UiFeedback.showToast({ message: '文章标题和内容为空，无法导出' })
      return
    }

    let content: string
    let extension: string
    let mimeType: string

    switch (format) {
      case 'markdown':
        content = this.exportToMarkdown()
        extension = 'md'
        mimeType = 'text/markdown'
        break
      case 'txt':
        content = this.exportToPlainText()
        extension = 'txt'
        mimeType = 'text/plain'
        break
      case 'html':
        content = this.exportToHtml()
        extension = 'html'
        mimeType = 'text/html'
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
    if (!content || content.length === 0) return 0
    // 简单统计中文字符和英文单词
    const chineseChars = content.match(/[\u4e00-\u9fa5]/g) || []
    const englishWords = content.match(/[a-zA-Z]+/g) || []
    return chineseChars.length + englishWords.length
  }

  // Markdown 转 HTML（用于预览）
  private markdownToHtml(md: string): string {
    if (!md || md.length === 0) return '<p style="color: #999;">暂无内容</p>'

    let html: string = md

    // 转义 HTML 特殊字符（代码块内的内容需要保护）
    const codeBlocks: string[] = []
    html = html.replace(/```([\s\S]*?)```/g, (match: string) => {
      codeBlocks.push(match)
      return `___CODE_BLOCK_${codeBlocks.length - 1}___`
    })

    const inlineCodes: string[] = []
    html = html.replace(/`([^`]+)`/g, (match: string, code: string) => {
      inlineCodes.push(code)
      return `___INLINE_CODE_${inlineCodes.length - 1}___`
    })

    // 转换标题 h1-h6
    html = html.replace(/^######\s+(.+)$/gm, '<h6 style="margin: 8px 0; font-size: 14px; color: #333;">$1</h6>')
    html = html.replace(/^#####\s+(.+)$/gm, '<h5 style="margin: 10px 0; font-size: 15px; color: #333;">$1</h5>')
    html = html.replace(/^####\s+(.+)$/gm, '<h4 style="margin: 12px 0; font-size: 16px; color: #333;">$1</h4>')
    html = html.replace(/^###\s+(.+)$/gm, '<h3 style="margin: 14px 0; font-size: 18px; color: #333;">$1</h3>')
    html = html.replace(/^##\s+(.+)$/gm, '<h2 style="margin: 16px 0; font-size: 20px; color: #333; border-bottom: 1px solid #eee; padding-bottom: 8px;">$1</h2>')
    html = html.replace(/^#\s+(.+)$/gm, '<h1 style="margin: 20px 0; font-size: 24px; color: #333; border-bottom: 2px solid #333; padding-bottom: 10px;">$1</h1>')

    // 转换粗体 **text** 或 __text__
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong style="font-weight: bold;">$1</strong>')
    html = html.replace(/__(.+?)__/g, '<strong style="font-weight: bold;">$1</strong>')

    // 转换斜体 *text* 或 _text_ (但排除已转换的 **)
    html = html.replace(/\*(.+?)\*/g, '<em style="font-style: italic;">$1</em>')
    html = html.replace(/_(.+?)_/g, '<em style="font-style: italic;">$1</em>')

    // 转换删除线 ~~text~~
    html = html.replace(/~~(.+?)~~/g, '<del style="text-decoration: line-through;">$1</del>')

    // 转换链接 [text](url)
    html = html.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2" style="color: #007DFF; text-decoration: none;">$1</a>')

    // 转换图片 ![alt](url)
    html = html.replace(/!\[([^\]]*)\]\(([^\)]+)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; height: auto; border-radius: 4px; margin: 8px 0;">')

    // 转换无序列表 - item 或 * item 或 + item
    html = html.replace(/^[\*\-\+]\s+(.+)$/gm, '<li style="margin: 4px 0; margin-left: 20px;">$1</li>')
    // 包裹 ul 标签
    html = html.replace(/(<li[^>]*>[\s\S]*?<\/li>\n?)+/g, '<ul style="margin: 8px 0; padding-left: 20px;">$&</ul>')
    // 移除嵌套的 ul
    html = html.replace(/<\/ul>\s*<ul[^>]*>/g, '')

    // 转换有序列表 1. item
    html = html.replace(/^\d+\.\s+(.+)$/gm, '<li style="margin: 4px 0; margin-left: 20px;">$1</li>')
    html = html.replace(/(<li[^>]*>[\s\S]*?<\/li>\n?)+/g, (match: string) => {
      if (match.includes('<ul')) return match
      return `<ol style="margin: 8px 0; padding-left: 20px;">${match}</ol>`
    })

    // 转换引用 > text
    html = html.replace(/^>\s*(.+)$/gm, '<blockquote style="margin: 12px 0; padding: 8px 16px; border-left: 4px solid #007DFF; background: #f5f5f5; color: #666;">$1</blockquote>')

    // 转换水平分割线 --- 或 *** 或 ___
    html = html.replace(/^(---|___|\*\*\*)$/gm, '<hr style="border: none; border-top: 1px solid #e4e5e7; margin: 16px 0;">')

    // 恢复内联代码
    inlineCodes.forEach((code: string, index: number) => {
      html = html.replace(
        `___INLINE_CODE_${index}___`,
        `<code style="background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; font-size: 0.9em;">${code}</code>`
      )
    })

    // 恢复代码块
    codeBlocks.forEach((block: string, index: number) => {
      const code = block.replace(/```/g, '').trim()
      html = html.replace(
        `___CODE_BLOCK_${index}___`,
        `<pre style="background: #f8f8f8; padding: 16px; overflow-x: auto; border-radius: 8px; margin: 12px 0;"><code style="font-family: monospace; font-size: 13px; line-height: 1.5;">${code}</code></pre>`
      )
    })

    // 转换段落（简单处理：将连续空行分隔的文本包裹在p标签中）
    const paragraphs: string[] = html.split(/\n\n+/)
    html = paragraphs.map((p: string) => {
      const trimmed: string = p.trim()
      if (trimmed.length === 0) return ''
      // 如果已经是块级元素，不再包裹
      if (trimmed.startsWith('<h') ||
          trimmed.startsWith('<pre') ||
          trimmed.startsWith('<ul') ||
          trimmed.startsWith('<ol') ||
          trimmed.startsWith('<blockquote') ||
          trimmed.startsWith('<hr') ||
          trimmed.startsWith('<li')) {
        return trimmed
      }
      // 行内转换换行符为 <br>
      return `<p style="margin: 8px 0; line-height: 1.6;">${trimmed.replace(/\n/g, '<br>')}</p>`
    }).join('\n')

    // 包装在容器中
    return `<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #333; line-height: 1.6;">${html}</div>`
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
            this.PanelTabs()

            // 当前面板内容
            if (this.activePanel === 'ai') {
              this.AIPanel()
            } else if (this.activePanel === 'publish') {
              this.PublishPanel()
            } else if (this.activePanel === 'version') {
              this.VersionPanel()
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
      .backgroundColor(Colors.BG_SECONDARY)
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
        .fontColor(Colors.TEXT_PRIMARY)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.SM }) {
        // 导出按钮
        Button('导出')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
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
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .enabled(!this.saving && !this.generating)
          .onClick(() => {
            this.handleSave()
          })

        // 发布
        Button(this.publishing ? '发布中...' : (this.wordpressPostId.length > 0 ? '更新' : '发布'))
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(this.publishing ? Colors.PRIMARY_DISABLED : Colors.PRIMARY)
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
    .backgroundColor(Colors.BG_PRIMARY)
    .border({ width: { bottom: 0.5 }, color: Colors.DIVIDER })
  }

  // 标题输入
  @Builder
  TitleSection() {
    TextInput({ text: this.title, placeholder: '输入文章标题...' })
      .fontSize(Typography.TITLE)
      .fontColor(Colors.TEXT_PRIMARY)
      .placeholderColor(Colors.TEXT_HINT)
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
        .fontColor(Colors.TEXT_SECONDARY)

      TextInput({ text: this.keywords, placeholder: '输入关键词，用逗号分隔' })
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)
        .placeholderColor(Colors.TEXT_HINT)
        .height(ComponentSize.INPUT_HEIGHT)
        .backgroundColor(Colors.BG_PRIMARY)
        .borderRadius(Radius.SM)
        .onChange((value: string) => {
          this.keywords = value
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: Spacing.SM })
  }

  // 格式化工具栏
  @Builder
  FormatToolbar() {
    Scroll() {
      Row({ space: Spacing.XS }) {
        // 粗体
        Text('B')
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('**', '**', '粗体文本') })

        // 斜体
        Text('I')
          .fontSize(Typography.BODY)
          .fontStyle(FontStyle.Italic)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('*', '*', '斜体文本') })

        // H1
        Text('H1')
          .fontSize(Typography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(36)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n# ', '\n', '标题\n') })

        // H2
        Text('H2')
          .fontSize(Typography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(36)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n## ', '\n', '小标题\n') })

        // H3
        Text('H3')
          .fontSize(Typography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(36)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n### ', '\n', '子标题\n') })

        // 无序列表
        Text('UL')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n- ', '\n', '列表项\n') })

        // 有序列表
        Text('OL')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n1. ', '\n', '列表项\n') })

        // 代码
        Text('` `')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(40)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('`', '`', '代码') })

        // 代码块
        Text('{}')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('\n```\n', '\n```\n', '代码块\n') })

        // 链接
        Text('Link')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(44)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('[', '](URL)', '链接文本') })

        // 图片
        Text('Img')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_PRIMARY)
          .width(40)
          .height(32)
          .textAlign(TextAlign.Center)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.SM)
          .onClick(() => { this.insertMarkdown('![', '](URL)', '图片描述') })
      }
      .padding({ left: Spacing.XS, right: Spacing.XS })
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .scrollBar(BarState.Off)
  }

  // 内容编辑区
  @Builder
  ContentSection() {
    Column({ space: Spacing.XS }) {
      // 顶部工具栏行
      Row() {
        Text('内容')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)

        Blank()

        // 编辑器模式切换
        Row({ space: Spacing.XS }) {
          Text('Markdown')
            .fontSize(Typography.CAPTION)
            .fontColor(this.editorMode === 'markdown' ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
            .fontWeight(this.editorMode === 'markdown' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .backgroundColor(this.editorMode === 'markdown' ? 'rgba(0,125,255,0.1)' : Color.Transparent)
            .borderRadius(Radius.SM)
            .onClick(() => { this.editorMode = 'markdown' })

          Text('纯文本')
            .fontSize(Typography.CAPTION)
            .fontColor(this.editorMode === 'plain' ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
            .fontWeight(this.editorMode === 'plain' ? FontWeight.Medium : FontWeight.Normal)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .backgroundColor(this.editorMode === 'plain' ? 'rgba(0,125,255,0.1)' : Color.Transparent)
            .borderRadius(Radius.SM)
            .onClick(() => {
              this.editorMode = 'plain'
              this.previewMode = false
            })
        }

        // 分隔线
        Divider()
          .vertical(true)
          .height(20)
          .strokeWidth(1)
          .color(Colors.DIVIDER)
          .margin({ left: Spacing.SM, right: Spacing.SM })

        // 编辑/预览切换（仅 Markdown 模式显示）
        if (this.editorMode === 'markdown') {
          Row({ space: Spacing.XS }) {
            Text('编辑')
              .fontSize(Typography.CAPTION)
              .fontColor(!this.previewMode ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
              .fontWeight(!this.previewMode ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
              .backgroundColor(!this.previewMode ? 'rgba(0,125,255,0.1)' : Color.Transparent)
              .borderRadius(Radius.SM)
              .onClick(() => { this.previewMode = false })

            Text('预览')
              .fontSize(Typography.CAPTION)
              .fontColor(this.previewMode ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
              .fontWeight(this.previewMode ? FontWeight.Medium : FontWeight.Normal)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
              .backgroundColor(this.previewMode ? 'rgba(0,125,255,0.1)' : Color.Transparent)
              .borderRadius(Radius.SM)
              .onClick(() => { this.previewMode = true })
          }
        }

        // 生成状态指示
        if (this.generating) {
          Row({ space: Spacing.XS }) {
            LoadingProgress()
              .width(14)
              .height(14)
              .color(Colors.PRIMARY)
            Text(`${Math.floor(this.generateProgress)}%`)
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.PRIMARY)
          }
          .margin({ left: Spacing.SM })
        }
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)

      // Markdown 工具栏（仅在 Markdown 编辑模式下显示）
      if (this.editorMode === 'markdown' && !this.previewMode) {
        this.FormatToolbar()
      }

      // 内容编辑区或预览区
      if (this.editorMode === 'markdown' && this.previewMode) {
        // 预览模式
        Scroll() {
          RichText(this.markdownToHtml(this.content))
            .width('100%')
            .padding(Spacing.MD)
        }
        .width('100%')
        .height(300)
        .backgroundColor(Colors.BG_PRIMARY)
        .borderRadius(Radius.SM)
      } else {
        // 编辑模式（Markdown 或纯文本）
        TextArea({ text: this.content, placeholder: this.editorMode === 'markdown' ? '输入 Markdown 内容...' : '输入文章内容...' })
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .width('100%')
          .height(300)
          .backgroundColor(Colors.BG_PRIMARY)
          .borderRadius(Radius.SM)
          .padding(Spacing.MD)
          .onChange((value: string) => {
            this.content = value
          })
      }
    }
    .width('100%')
    .padding({ top: Spacing.BASE })
  }

  // 面板切换标签
  @Builder
  PanelTabs() {
    Row({ space: 0 }) {
      this.PanelTab('AI 生成', 'ai')
      this.PanelTab('发布设置', 'publish')
      this.PanelTab(`版本历史${this.versions.length > 0 ? ` (${this.versions.length})` : ''}`, 'version')
    }
    .width('100%')
    .padding({ top: Spacing.LG })
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  PanelTab(label: string, panelKey: string) {
    Column() {
      Text(label)
        .fontSize(Typography.BODY)
        .fontWeight(this.activePanel === panelKey ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activePanel === panelKey ? Colors.PRIMARY : Colors.TEXT_SECONDARY)
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.SM })

      Divider()
        .width(this.activePanel === panelKey ? '100%' : '0%')
        .strokeWidth(2)
        .color(Colors.PRIMARY)
        .animation({ duration: AnimDuration.FAST })
    }
    .onClick(() => {
      this.activePanel = panelKey
    })
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
            .fontColor(Colors.TEXT_SECONDARY)

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
            .fontColor(Colors.TEXT_PRIMARY)
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
            .fontColor(Colors.TEXT_SECONDARY)

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
            .fontColor(Colors.TEXT_PRIMARY)
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
            .fontColor(Colors.TEXT_SECONDARY)

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
            .fontColor(Colors.TEXT_PRIMARY)
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
            .color(Colors.PRIMARY)

          Button('停止生成')
            .type(ButtonType.Normal)
            .width('100%')
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(Colors.ERROR)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(Colors.ERROR)
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
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(Colors.PRIMARY)
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
        .fontColor(Colors.PRIMARY)
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor(Colors.PRIMARY)
        .borderRadius(Radius.SM)
        .enabled(!this.generatingImage && !this.generating)
        .onClick(() => { this.handleOpenImageDialog() })
    }
    .width('100%')
    .padding({ top: Spacing.BASE })
    .backgroundColor(Colors.BG_PRIMARY)
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
          .fontColor(Colors.TEXT_PRIMARY)

        Blank()

        Button('X')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .backgroundColor(Color.Transparent)
          .width(36)
          .height(36)
          .onClick(() => {
            this.showImageDialog = false
          })
      }
      .width('100%')

      // 图片描述输入
      Column({ space: Spacing.XS }) {
        Text('图片描述')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)

        TextArea({ text: this.imagePrompt, placeholder: '输入图片描述...' })
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .width('100%')
          .height(80)
          .backgroundColor(Colors.BG_SECONDARY)
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
          .fontColor(Colors.TEXT_SECONDARY)

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
          .fontColor(Colors.TEXT_PRIMARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // API Key 输入
      Column({ space: Spacing.XS }) {
        Text('API Key')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)

        TextInput({ text: this.imageApiKey, placeholder: '输入 API Key' })
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(Colors.BG_SECONDARY)
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
          .fontColor(Colors.TEXT_SECONDARY)

        TextInput({ text: this.imageEndpoint, placeholder: '使用默认端点' })
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(Colors.BG_SECONDARY)
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
          .fontColor(Colors.TEXT_SECONDARY)

        TextInput({ text: this.imageModel, placeholder: '使用默认模型' })
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .width('100%')
          .height(ComponentSize.INPUT_HEIGHT)
          .backgroundColor(Colors.BG_SECONDARY)
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
          .fontColor(Colors.TEXT_SECONDARY)
          .width('100%')
      }

      // 按钮行
      Row({ space: Spacing.MD }) {
        Button('取消')
          .type(ButtonType.Normal)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .backgroundColor(Colors.BG_SECONDARY)
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
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY_DISABLED)
            .borderRadius(Radius.SM)
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .enabled(false)
        } else {
          Button('生成')
            .type(ButtonType.Normal)
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY)
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
    .backgroundColor(Colors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }

  // 发布面板
  @Builder
  PublishPanel() {
    Column({ space: Spacing.MD }) {
      // 站点选择
      Column({ space: Spacing.XS }) {
        Text('发布站点')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)

        if (this.sites.length > 0) {
          Select(this.sites.map((s: WordPressSite) => {
            const option: SelectOption = { value: s.siteName }
            return option
          }))
            .selected(this.sites.findIndex((s: WordPressSite) => s.id === this.siteId))
            .value(this.getSelectedSiteName())
            .onSelect((index: number) => {
              if (index >= 0 && index < this.sites.length) {
                this.siteId = this.sites[index].id
                this.selectedCategories = []
                this.loadCategories(this.siteId)
              }
            })
            .width('100%')
            .height(ComponentSize.INPUT_HEIGHT)
        } else {
          Text('暂无站点，请先添加')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_HINT)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // WordPress 分类
      if (this.wpCategories.length > 0) {
        Column({ space: Spacing.XS }) {
          Text('文章分类')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.wpCategories, (cat: WordPressCategory) => {
              Button(cat.name)
                .type(ButtonType.Normal)
                .fontSize(Typography.CAPTION)
                .fontColor(this.selectedCategories.includes(cat.id) ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
                .backgroundColor(this.selectedCategories.includes(cat.id) ? Colors.PRIMARY : Color.Transparent)
                .borderWidth(1)
                .borderColor(this.selectedCategories.includes(cat.id) ? Colors.PRIMARY : Colors.BORDER)
                .borderRadius(Radius.FULL)
                .height(32)
                .padding({ left: Spacing.MD, right: Spacing.MD })
                .margin({ right: Spacing.SM, bottom: Spacing.SM })
                .onClick(() => {
                  this.toggleCategory(cat.id)
                })
            }, (cat: WordPressCategory) => String(cat.id))
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // Slug 输入
      Column({ space: Spacing.XS }) {
        Text('文章别名 (Slug)')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)

        Row({ space: Spacing.SM }) {
          TextInput({ text: this.postSlug, placeholder: '自动生成或手动输入' })
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_PRIMARY)
            .placeholderColor(Colors.TEXT_HINT)
            .height(ComponentSize.INPUT_HEIGHT)
            .layoutWeight(1)
            .backgroundColor(Colors.BG_SECONDARY)
            .borderRadius(Radius.SM)
            .onChange((value: string) => {
              this.postSlug = value
            })

          Button(this.generatingSlug ? '...' : 'AI')
            .type(ButtonType.Normal)
            .fontSize(Typography.BODY)
            .fontColor(Colors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(Colors.PRIMARY)
            .borderRadius(Radius.SM)
            .height(ComponentSize.INPUT_HEIGHT)
            .width(56)
            .enabled(!this.generatingSlug)
            .onClick(() => {
              this.handleGenerateSlug()
            })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 状态指示
      if (this.wordpressPostId.length > 0) {
        Row({ space: Spacing.SM }) {
          Circle({ width: 8, height: 8 })
            .fill(Colors.SUCCESS)
          Text(`已发布 · Post ID: ${this.wordpressPostId}`)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.SUCCESS)
        }
        .width('100%')
      }
    }
    .width('100%')
    .backgroundColor(Colors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }

  // 版本历史面板
  @Builder
  VersionPanel() {
    Column({ space: Spacing.MD }) {
      if (this.versions.length === 0) {
        Column({ space: Spacing.SM }) {
          Text('暂无版本历史')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_HINT)
          Text('保存文章后会自动创建版本')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_HINT)
        }
        .width('100%')
        .padding({ top: Spacing.LG, bottom: Spacing.LG })
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.versions, (version: ArticleVersion) => {
          this.VersionItemBuilder(version)
        }, (version: ArticleVersion) => version.id)
      }
    }
    .width('100%')
    .backgroundColor(Colors.BG_PRIMARY)
    .borderRadius(Radius.MD)
    .padding(Spacing.BASE)
    .margin({ top: Spacing.MD })
  }

  @Builder
  VersionItemBuilder(version: ArticleVersion) {
    Column({ space: Spacing.XS }) {
      Row() {
        Column({ space: Spacing.XS }) {
          Row({ space: Spacing.SM }) {
            Text(`版本 ${version.versionNumber}`)
              .fontSize(Typography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
            Text(version.status === 'published' ? '已发布' : '草稿')
              .fontSize(Typography.LABEL)
              .fontColor(version.status === 'published' ? Colors.SUCCESS : Colors.TEXT_HINT)
              .padding({ left: Spacing.XS, right: Spacing.XS })
              .backgroundColor(version.status === 'published' ? 'rgba(76, 175, 80, 0.1)' : Colors.BG_SECONDARY)
              .borderRadius(Radius.SM)
          }

          Text(version.title)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: Spacing.SM }) {
            Text(formatDateTime(version.createdAt))
              .fontSize(Typography.LABEL)
              .fontColor(Colors.TEXT_HINT)
            Text(`| ${this.getContentLength(version.content)} 字`)
              .fontSize(Typography.LABEL)
              .fontColor(Colors.TEXT_HINT)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Row({ space: Spacing.SM }) {
          Button(this.expandedVersionIds.includes(version.id) ? '收起' : '详情')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)
            .backgroundColor(Color.Transparent)
            .height(32)
            .padding({ left: Spacing.SM, right: Spacing.SM })
            .onClick(() => { this.toggleVersionExpand(version.id) })

          Button('删除')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.ERROR)
            .backgroundColor(Color.Transparent)
            .height(32)
            .padding({ left: Spacing.SM, right: Spacing.SM })
            .onClick(() => { this.handleDeleteVersion(version) })

          Button('恢复')
            .type(ButtonType.Normal)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .borderWidth(1)
            .borderColor(Colors.PRIMARY)
            .borderRadius(Radius.SM)
            .height(32)
            .padding({ left: Spacing.MD, right: Spacing.MD })
            .onClick(() => { this.handleRestoreVersion(version) })
        }
      }
      .width('100%')

      if (this.expandedVersionIds.includes(version.id)) {
        Column({ space: Spacing.XS }) {
          Divider()
            .width('100%')
            .strokeWidth(0.5)
            .color(Colors.DIVIDER)
            .margin({ top: Spacing.SM, bottom: Spacing.SM })

          Text('内容预览:')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)

          Text(version.content.length > 200 ? version.content.substring(0, 200) + '...' : version.content)
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_PRIMARY)
            .maxLines(5)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (version.content.length > 200) {
              Text(`...共 ${this.getContentLength(version.content)} 字`)
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.TEXT_HINT)
          }
        }
        .width('100%')
        .padding({ top: Spacing.XS })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
    .border({ width: { bottom: 0.5 }, color: Colors.DIVIDER })
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

  getSelectedSiteName(): string {
    const found = this.sites.find((s: WordPressSite) => s.id === this.siteId)
    return found ? found.siteName : '选择站点'
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
