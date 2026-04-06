// 主题管理页面 — 对标 React Topics.tsx

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { Topic } from '../models/Topic'
import { TopicDao } from '../services/db/TopicDao'
import { AIStreamClient, ChatMessage, StreamOptions } from '../services/http/AIStreamClient'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import http from '@ohos.net.http'

@Component
export struct TopicsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  // 数据
  @State allTopics: Topic[] = []
  @State searchQuery: string = ''
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

  private getTopicStateLabel(topic: Topic): string {
    return topic.used ? '已进入文章流程' : '待带入文章'
  }

  private getTopicStateHint(topic: Topic): string {
    return topic.used
      ? '这个主题已带入文章编辑器，可继续打开编辑器补写或调整内容。'
      : '点击“写文章”会把主题带入文章编辑器，并自动标记为已进入文章流程。'
  }

  private getWriteActionLabel(topic: Topic): string {
    return topic.used ? '继续写文章' : '写文章'
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部工具栏
          this.ToolbarArea()

          // 搜索栏
          this.SearchBar()

          if (!this.isLoading && this.allTopics.length > 0) {
            this.WorkflowSummary()
          }

          // 内容区
          if (this.isLoading) {
            this.LoadingView()
          } else if (this.allTopics.length === 0) {
            this.EmptyView()
          } else {
            this.GroupList()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BG_PRIMARY)

        // 添加主题对话框
        if (this.showAddDialog) {
          this.AddTopicDialog()
        }

        // AI 生成对话框
        if (this.showGenerateDialog) {
          this.GenerateTopicDialog()
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
      // 标题 + 数量
      Column({ space: Spacing.XS }) {
        Text('主题库')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
        Text(`${this.getUnusedCount()} 个待带入文章 / ${this.getUsedCount()} 个已进入文章流程 / 共 ${this.getTotalCount()} 个主题`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 操作按钮
      Row({ space: Spacing.SM }) {
        if (this.getUsedCount() > 0) {
          Button('清除已用', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(Colors.ERROR)
            .backgroundColor('transparent')
            .borderWidth(1)
            .borderColor(Colors.BORDER)
            .onClick(() => {
              this.handleClearUsed()
            })
        }

        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.openAddDialog()
          })

        Button('AI 生成', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openGenerateDialog()
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 搜索栏 ==========

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: '搜索主题...', text: this.searchQuery })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .borderRadius(Radius.MD)
        .backgroundColor(Colors.BG_SECONDARY)
        .padding({ left: Spacing.BASE, right: Spacing.BASE })
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)
        .placeholderColor(Colors.TEXT_HINT)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchQuery = value
        })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
  }

  @Builder
  WorkflowSummary() {
    Column({ space: Spacing.XS }) {
      Text(`待带入文章 ${this.getUnusedCount()} · 已进入文章流程 ${this.getUsedCount()}`)
        .fontSize(Typography.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .width('100%')

      Text('主题沉淀的是文章方向；点击“写文章”会带入文章编辑器，进入过文章流程的主题可继续补写。')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(Colors.BG_SECONDARY)
    .alignItems(HorizontalAlign.Start)
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
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无主题')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('添加主题来沉淀文章方向，后续可带入文章编辑器继续写作')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.MD }) {
        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.openAddDialog()
          })

        Button('AI 生成', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openGenerateDialog()
          })
      }
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 分组列表 ==========

  @Builder
  GroupList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        ForEach(Object.keys(this.getGroupedTopics()), (category: string) => {
          this.GroupCard(category, this.getGroupedTopics()[category] as Topic[])
        }, (category: string) => category)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  GroupCard(category: string, topics: Topic[]) {
    Column({ space: Spacing.MD }) {
      // 分组头部
      Row() {
        Row({ space: Spacing.SM }) {
          Text(category)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
          Text(`${topics.length}`)
            .fontSize(Typography.LABEL)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 主题条目列表
      Column({ space: Spacing.SM }) {
        ForEach(topics, (topic: Topic) => {
          this.TopicItem(topic)
        }, (topic: Topic) => topic.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  TopicItem(topic: Topic) {
    Column({ space: Spacing.SM }) {
      // 标题行 + 状态标签
      Row() {
        Text(topic.title)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.getTopicStateLabel(topic))
          .fontSize(Typography.LABEL)
          .fontColor(topic.used ? Colors.SUCCESS : Colors.PRIMARY)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
          .borderRadius(Radius.FULL)
      }
      .width('100%')

      // 描述（2行截断）
      if (topic.description.length > 0) {
        Text(topic.description)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      Text(this.getTopicStateHint(topic))
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')

      // 关键词标签
      if (topic.keywords.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(topic.keywords.split(/[,，]/), (kw: string) => {
            if (kw.trim().length > 0) {
              Text(kw.trim())
                .fontSize(Typography.CAPTION)
                .fontColor(Colors.PRIMARY)
                .backgroundColor('#E8F3FF')
                .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
                .borderRadius(Radius.FULL)
                .margin({ right: Spacing.XS, bottom: Spacing.XS })
            }
          }, (kw: string, index: number) => `${topic.id}_kw_${index}`)
        }
        .width('100%')
      }

      // 操作按钮
      Row({ space: Spacing.SM }) {
        Button(this.getWriteActionLabel(topic), { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(Colors.PRIMARY)
          .onClick(() => {
            this.handleStartArticleFromTopic(topic)
          })

        if (!topic.used) {
          Button('标记已进入流程', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
            .backgroundColor('transparent')
            .borderWidth(1)
            .borderColor(Colors.BORDER)
            .onClick(() => {
              this.handleMarkUsed(topic)
            })
        }

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.handleDeleteTopic(topic)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(Colors.BG_PRIMARY)
  }

  // ========== 添加主题对话框 ==========

  @Builder
  AddTopicDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.isSubmitting) {
            this.showAddDialog = false
          }
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
      // 标题 + 关闭
      Row() {
        Text('添加主题')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([Colors.TEXT_HINT])
          .onClick(() => {
            if (!this.isSubmitting) {
              this.showAddDialog = false
            }
          })
      }
      .width('100%')

      // 标题（必填）
      Column({ space: Spacing.XS }) {
        Text('标题')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '输入主题标题', text: this.formTitle })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => { this.formTitle = v })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 描述
      Column({ space: Spacing.XS }) {
        Text('描述（可选）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextArea({ placeholder: '输入主题描述', text: this.formDescription })
          .height(100)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding(Spacing.BASE)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => { this.formDescription = v })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 关键词
      Column({ space: Spacing.XS }) {
        Text('关键词（可选，逗号分隔）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '关键词1, 关键词2, 关键词3', text: this.formKeywords })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => { this.formKeywords = v })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 分类
      Column({ space: Spacing.XS }) {
        Text('分类（可选）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：未分类', text: this.formCategory })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => { this.formCategory = v })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 操作按钮
      Row({ space: Spacing.MD }) {
        Button('取消', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .backgroundColor(Colors.BG_SECONDARY)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.showAddDialog = false
          })

        Button(this.isSubmitting ? '保存中...' : '保存', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .enabled(!this.isSubmitting)
          .onClick(() => {
            this.handleSaveTopic()
          })
      }
      .width('100%')
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
    .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
    .backgroundColor(Colors.BG_PRIMARY)
    .position({ x: 0, y: '100%' })
    .translate({ y: this.showAddDialog ? '-100%' : '0' })
    .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  // ========== AI 生成主题对话框 ==========

  @Builder
  GenerateTopicDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
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
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([Colors.TEXT_HINT])
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
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '例如：WordPress 性能优化', text: this.generateTopic })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
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
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '10', text: this.generateCount.toString() })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
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
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：AI 生成', text: this.generateCategory })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
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
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
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
            .fontColor(Colors.TEXT_PRIMARY)
            .width('100%')

          Scroll() {
            Text(this.generatedText)
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.TEXT_PRIMARY)
              .fontFamily('monospace')
              .width('100%')
          }
          .constraintSize({ maxHeight: 200 })
          .scrollBar(BarState.Off)
          .backgroundColor(Colors.BG_SECONDARY)
          .borderRadius(Radius.MD)
          .padding(Spacing.MD)

          // 保存按钮（生成完毕后显示）
          if (!this.isGenerating) {
            Button('保存到主题库', { type: ButtonType.Capsule })
              .width('100%')
              .height(ComponentSize.BUTTON_HEIGHT)
              .backgroundColor(Colors.PRIMARY)
              .fontColor(Colors.TEXT_ON_PRIMARY)
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
    .backgroundColor(Colors.BG_PRIMARY)
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
    const param: Record<string, string> = {}
    param['articleId'] = 'new'
    param['sourceType'] = 'topic'
    param['sourceId'] = topic.id
    param['initialTitle'] = topic.title
    param['initialKeywords'] = topic.keywords
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
        fontColor: Colors.ERROR,
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
