// 主题管理页面 — 对标 React Topics.tsx

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes, ArticleEditorNavParam } from '../constants/Routes'
import { Topic } from '../models/Topic'
import { TopicDao } from '../services/db/TopicDao'
import { AIStreamClient, ChatMessage, StreamOptions } from '../services/http/AIStreamClient'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { TopicAddDialogComponent } from '../components/topic/TopicAddDialog'
import { TopicGroupListComponent, TopicGroupViewModel } from '../components/topic/TopicGroupList'
import { TopicsHeaderPanelComponent } from '../components/topic/TopicsHeaderPanel'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { BasicDataSource } from '../utils/BasicDataSource'
import http from '@ohos.net.http'
import { AppStorageKeys } from '../constants/AppStorageKeys'

@Component
export struct TopicsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''

  // 数据
  @State @Watch('refreshGroupDataSource') allTopics: Topic[] = []
  @State @Watch('refreshGroupDataSource') searchQuery: string = ''
  @State isLoading: boolean = true

  // 添加对话框
  @State showAddDialog: boolean = false
  @State formTitle: string = ''
  @State formDescription: string = ''
  @State formKeywords: string = ''
  @State formCategory: string = ''
  @State isSubmitting: boolean = false

  // AI 生成对话框
  @State showGenerateDialog: boolean = false
  @State generateTopic: string = ''
  @State generateCount: number = 10
  @State generateCategory: string = ''
  @State isGenerating: boolean = false
  @State generatedText: string = ''
  @State currentStreamRequest: http.HttpRequest | null = null
  private groupDataSource: BasicDataSource<TopicGroupViewModel> = new BasicDataSource<TopicGroupViewModel>([])

  aboutToAppear(): void {
    this.loadTopics()
  }

  // ========== 计算属性 ==========

  getGroupedTopics(): Record<string, Topic[]> {
    const query = this.searchQuery.trim().toLowerCase()
    let filtered: Topic[] = []
    for (let i = 0; i < this.allTopics.length; i++) {
      const topic = this.allTopics[i]
      if (query.length === 0 ||
        topic.title.toLowerCase().includes(query) ||
        topic.description.toLowerCase().includes(query)) {
        filtered.push(topic)
      }
    }
    const grouped: Record<string, Topic[]> = {}
    for (let i = 0; i < filtered.length; i++) {
      const topic = filtered[i]
      const cat = topic.category.length > 0 ? topic.category : '未分类'
      if (!grouped[cat]) {
        grouped[cat] = []
      }
      (grouped[cat] as Topic[]).push(topic)
    }
    return grouped
  }

  private refreshGroupDataSource(): void {
    const grouped = this.getGroupedTopics()
    const categories = Object.keys(grouped)
    const data: TopicGroupViewModel[] = []
    for (let i = 0; i < categories.length; i++) {
      const item = new TopicGroupViewModel()
      item.category = categories[i]
      item.topics = grouped[categories[i]] as Topic[]
      data.push(item)
    }
    this.groupDataSource.setData(data)
  }

  getTotalCount(): number {
    return this.allTopics.length
  }

  getUnusedCount(): number {
    let count = 0
    for (let i = 0; i < this.allTopics.length; i++) {
      if (!this.allTopics[i].used) {
        count++
      }
    }
    return count
  }

  getUsedCount(): number {
    let count = 0
    for (let i = 0; i < this.allTopics.length; i++) {
      if (this.allTopics[i].used) {
        count++
      }
    }
    return count
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          TopicsHeaderPanelComponent({
            searchQuery: $searchQuery,
            unusedCount: this.getUnusedCount(),
            usedCount: this.getUsedCount(),
            totalCount: this.getTotalCount(),
            onClearUsed: () => {
              this.handleClearUsed()
            },
            onOpenAdd: () => {
              this.openAddDialog()
            },
            onOpenGenerate: () => {
              this.openGenerateDialog()
            }
          })

          TopicGroupListComponent({
            isLoading: this.isLoading,
            totalCount: this.getTotalCount(),
            dataSource: this.groupDataSource,
            onOpenAdd: () => {
              this.openAddDialog()
            },
            onOpenGenerate: () => {
              this.openGenerateDialog()
            },
            onWriteTopic: (topic: Topic) => {
              this.handleStartArticleFromTopic(topic)
            },
            onMarkUsed: (topic: Topic) => {
              this.handleMarkUsed(topic)
            },
            onDeleteTopic: (topic: Topic) => {
              this.handleDeleteTopic(topic)
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.BG_PRIMARY)

        if (this.showAddDialog) {
          TopicAddDialogComponent({
            isSubmitting: this.isSubmitting,
            formTitle: $formTitle,
            formDescription: $formDescription,
            formKeywords: $formKeywords,
            formCategory: $formCategory,
            onClose: () => {
              this.showAddDialog = false
            },
            onSubmit: () => {
              this.handleSaveTopic()
            }
          })
        }

        if (this.showGenerateDialog) {
          this.GenerateTopicDialog()
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== AI 生成主题对话框 ==========

  @Builder
  GenerateTopicDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          if (!this.isGenerating) {
            this.showGenerateDialog = false
          }
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
      // 标题 + 关闭
      Row() {
        Text('AI 生成主题')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([ResourceColors.TEXT_HINT])
          .onClick(() => {
            if (!this.isGenerating) {
              this.showGenerateDialog = false
            }
          })
      }
      .width('100%')

      // 主题方向
      Column({ space: Spacing.XS }) {
        Text('主题方向')
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '例如：WordPress 性能优化', text: this.generateTopic })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .enabled(!this.isGenerating)
          .onChange((v: string) => {
            this.generateTopic = v
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 生成数量
      Column({ space: Spacing.XS }) {
        Text('生成数量（1-20）')
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '10', text: this.generateCount.toString() })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .type(InputType.Number)
          .enabled(!this.isGenerating)
          .onChange((v: string) => {
            const num = parseInt(v)
            if (!isNaN(num) && num >= 1 && num <= 20) {
              this.generateCount = num
            }
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 分类
      Column({ space: Spacing.XS }) {
        Text('分类（可选）')
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：AI 生成', text: this.generateCategory })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .enabled(!this.isGenerating)
          .onChange((v: string) => {
            this.generateCategory = v
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 开始生成按钮
      Button(this.isGenerating ? '生成中...' : '开始生成', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isGenerating && this.generateTopic.trim().length > 0)
        .onClick(() => {
          this.handleStartGenerate()
        })

      // 流式输出结果区域
      if (this.generatedText.length > 0) {
        Column({ space: Spacing.SM }) {
          Text('生成结果')
            .fontSize(Typography.BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .width('100%')

          Scroll() {
            Text(this.generatedText)
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.TEXT_PRIMARY)
              .fontFamily('monospace')
              .width('100%')
          }
          .constraintSize({ maxHeight: 200 })
          .scrollBar(BarState.Off)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .borderRadius(Radius.MD)
          .padding(Spacing.MD)

          // 保存按钮（生成完毕后显示）
          if (!this.isGenerating) {
            Button('保存到主题库', { type: ButtonType.Capsule })
              .width('100%')
              .height(ComponentSize.BUTTON_HEIGHT)
              .backgroundColor(ResourceColors.PRIMARY)
              .fontColor(ResourceColors.TEXT_ON_PRIMARY)
              .fontSize(Typography.BODY_LARGE)
              .fontWeight(FontWeight.Medium)
              .onClick(() => {
                this.handleSaveGenerated()
              })
          }
        }
        .width('100%')
        .padding({ top: Spacing.SM })
      }
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
    .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .position({ x: 0, y: '100%' })
    .translate({ y: this.showGenerateDialog ? '-100%' : '0' })
    .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 业务逻辑 ==========

  private async loadTopics(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.allTopics = []
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      this.allTopics = await TopicDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load topics failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载主题失败' })
    } finally {
      this.isLoading = false
    }
  }

  private openAddDialog(): void {
    this.formTitle = ''
    this.formDescription = ''
    this.formKeywords = ''
    this.formCategory = ''
    this.showAddDialog = true
  }

  private openGenerateDialog(): void {
    this.generateTopic = ''
    this.generateCount = 10
    this.generateCategory = ''
    this.generatedText = ''
    this.currentStreamRequest = null
    this.showGenerateDialog = true
  }

  private async handleSaveTopic(): Promise<void> {
    if (this.formTitle.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入主题标题' })
      return
    }

    this.isSubmitting = true
    try {
      await TopicDao.insert(
        this.currentUserId,
        this.formTitle.trim(),
        this.formDescription.trim(),
        this.formKeywords.trim(),
        this.formCategory.trim()
      )
      UiFeedback.showToast({ message: '主题添加成功', duration: 2000 })
      this.showAddDialog = false
      await this.loadTopics()
    } catch (err) {
      Logger.error('Save topic failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '添加主题失败' })
    } finally {
      this.isSubmitting = false
    }
  }

  private async handleStartGenerate(): Promise<void> {
    if (this.generateTopic.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入主题方向' })
      return
    }

    this.isGenerating = true
    this.generatedText = ''

    try {
      const aiSettings = await AISettingsDao.findDefault(this.currentUserId)
      if (aiSettings === null) {
      UiFeedback.showToast({ message: '请先配置 AI 设置' })
        this.isGenerating = false
        return
      }

      if (aiSettings.apiEndpoint.length === 0 || aiSettings.apiKey.length === 0) {
      UiFeedback.showToast({ message: 'AI 配置不完整，请检查 API 端点和密钥' })
        this.isGenerating = false
        return
      }

      const topicDir = this.generateTopic.trim()
      const count = this.generateCount

      const prompt = `请为我生成 ${count} 个关于"${topicDir}"的文章主题创意。
对于每个主题，请按以下格式输出：
---
标题: [文章标题]
描述: [2-3句话的大纲描述]
关键词: [3-5个相关关键词，用逗号分隔]
---
要求：
1. 主题要具有实用价值和吸引力
2. 标题要吸引眼球，适合 SEO
3. 每个主题要有独特的角度
4. 描述要清晰说明文章内容方向
请直接输出，不要添加其他说明。`

      const systemMsg = new ChatMessage()
      systemMsg.role = 'system'
      systemMsg.content = '你是一个专业的内容策划专家，擅长为博客和网站规划优质文章主题。'

      const userMsg = new ChatMessage()
      userMsg.role = 'user'
      userMsg.content = prompt

      // 确保端点格式正确
      let endpoint = aiSettings.apiEndpoint
      if (!endpoint.includes('/chat/completions') && !endpoint.includes('/v1/')) {
        endpoint = endpoint.replace(/\/$/, '') + '/chat/completions'
      }

      const opts = new StreamOptions()
      opts.endpoint = endpoint
      opts.apiKey = aiSettings.apiKey
      opts.model = aiSettings.model
      opts.messages = [systemMsg, userMsg]
      opts.onUpdate = (content: string) => {
        this.generatedText = content
      }
      opts.onComplete = () => {
        this.isGenerating = false
        UiFeedback.showToast({ message: '生成完成', duration: 2000 })
      }
      opts.onError = (error: string) => {
        this.isGenerating = false
        Logger.error('AI generate topics error: %{public}s', error)
        UiFeedback.showToast({ message: 'AI 生成失败，请检查网络和配置' })
      }

      this.currentStreamRequest = AIStreamClient.sendStream(opts)
    } catch (err) {
      this.isGenerating = false
      Logger.error('Start generate topics failed: %{public}s', String(err))
      UiFeedback.showToast({ message: 'AI 生成失败' })
    }
  }

  private async handleSaveGenerated(): Promise<void> {
    if (this.generatedText.trim().length === 0) {
      UiFeedback.showToast({ message: '没有可保存的内容' })
      return
    }

    try {
      const category = this.generateCategory.trim().length > 0 ? this.generateCategory.trim() : 'AI 生成'
      const blocks = this.generatedText.split('---')
      let savedCount = 0

      for (let i = 0; i < blocks.length; i++) {
        const block = blocks[i].trim()
        if (block.length === 0) {
          continue
        }

        const titleMatch = block.match(/标题[:：]\s*(.+)/)
        if (titleMatch !== null && titleMatch.length > 1) {
          const title = (titleMatch[1] as string).trim()
          let desc = ''
          let kws = ''

          const descMatch = block.match(/描述[:：]\s*(.+)/)
          if (descMatch !== null && descMatch.length > 1) {
            desc = (descMatch[1] as string).trim()
          }

          const kwMatch = block.match(/关键词[:：]\s*(.+)/)
          if (kwMatch !== null && kwMatch.length > 1) {
            kws = (kwMatch[1] as string).trim()
          }

          await TopicDao.insert(this.currentUserId, title, desc, kws, category)
          savedCount++
        }
      }

      if (savedCount > 0) {
        UiFeedback.showToast({ message: `成功保存 ${savedCount} 个主题`, duration: 2000 })
        this.showGenerateDialog = false
        await this.loadTopics()
      } else {
        UiFeedback.showToast({ message: '未能解析出有效主题，请检查生成内容' })
      }
    } catch (err) {
      Logger.error('Save generated topics failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '保存失败' })
    }
  }

  private async handleMarkUsed(topic: Topic): Promise<void> {
    try {
      await TopicDao.markUsed(topic.id)
      this.syncTopicUsedState(topic.id)
      UiFeedback.showToast({ message: `"${topic.title}" 已进入文章流程`, duration: 2000 })
    } catch (err) {
      Logger.error('Mark topic used failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '操作失败' })
    }
  }

  private async handleStartArticleFromTopic(topic: Topic): Promise<void> {
    if (!topic.used) {
      try {
        await TopicDao.markUsed(topic.id)
        this.syncTopicUsedState(topic.id)
          UiFeedback.showToast({ message: `"${topic.title}" 已带入文章编辑器`, duration: 1500 })
      } catch (err) {
        Logger.error('Mark topic used before editor failed: %{public}s', String(err))
        UiFeedback.showToast({ message: '状态更新失败，仍将打开编辑器' })
      }
    }

    this.navigateToEditorFromTopic(topic)
  }

  private navigateToEditorFromTopic(topic: Topic): void {
    const param = new ArticleEditorNavParam()
    param.articleId = 'new'
    param.sourceType = 'topic'
    param.sourceId = topic.id
    param.initialTitle = topic.title
    param.initialKeywords = topic.keywords
    this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
  }

  private syncTopicUsedState(topicId: string): void {
    const nextTopics: Topic[] = []
    for (let i = 0; i < this.allTopics.length; i++) {
      const current = this.allTopics[i]
      if (current.id === topicId) {
        current.used = true
      }
      nextTopics.push(current)
    }
    this.allTopics = nextTopics
  }

  private async handleDeleteTopic(topic: Topic): Promise<void> {
    try {
      await TopicDao.deleteById(topic.id)
      UiFeedback.showToast({ message: `已删除"${topic.title}"`, duration: 2000 })
      await this.loadTopics()
    } catch (err) {
      Logger.error('Delete topic failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }

  private handleClearUsed(): void {
    const usedTopics: Topic[] = []
    for (let i = 0; i < this.allTopics.length; i++) {
      if (this.allTopics[i].used) {
        usedTopics.push(this.allTopics[i])
      }
    }

    if (usedTopics.length === 0) {
      UiFeedback.showToast({ message: '没有已进入文章流程的主题' })
      return
    }

    UiFeedback.showConfirm({
      title: '确认清除',
      message: `确定要删除 ${usedTopics.length} 个已进入文章流程的主题吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: ResourceColors.ERROR,
        action: () => {
          this.doClearUsed(usedTopics)
        }
      }
    })
  }

  private async doClearUsed(usedTopics: Topic[]): Promise<void> {
    try {
      for (let i = 0; i < usedTopics.length; i++) {
        await TopicDao.deleteById(usedTopics[i].id)
      }
      UiFeedback.showToast({ message: `已清除 ${usedTopics.length} 个已进入文章流程的主题`, duration: 2000 })
      await this.loadTopics()
    } catch (err) {
      Logger.error('Clear used topics failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '清除失败' })
    }
  }
}
