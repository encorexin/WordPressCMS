// 关键词管理页面 — 对标 React Keywords.tsx

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { Keyword } from '../models/Keyword'
import { KeywordDao } from '../services/db/KeywordDao'
import { AIStreamClient, ChatMessage } from '../services/http/AIStreamClient'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

@Component
export struct KeywordsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  // 数据
  @State allKeywords: Keyword[] = []
  @State searchQuery: string = ''
  @State isLoading: boolean = true

  // 添加对话框
  @State showAddDialog: boolean = false
  @State formKeywords: string = ''
  @State formGroupName: string = ''
  @State isSubmitting: boolean = false

  // AI 获取对话框
  @State showFetchDialog: boolean = false
  @State fetchTopic: string = ''
  @State fetchCount: number = 20
  @State fetchGroupName: string = ''
  @State isFetching: boolean = false
  @State fetchedKeywords: string[] = []
  @State selectedFetched: boolean[] = []

  // 分组删除确认对话框
  @State showGroupDeleteConfirm: boolean = false
  @State groupToDelete: string = ''
  @State isDeletingGroup: boolean = false

  aboutToAppear(): void {
    this.loadKeywords()
  }

  // ========== 计算属性 ==========

  getGroupedKeywords(): Record<string, Keyword[]> {
    const query = this.searchQuery.trim().toLowerCase()
    let filtered: Keyword[] = []
    for (let i = 0; i < this.allKeywords.length; i++) {
      const kw = this.allKeywords[i]
      if (query.length === 0 || kw.keyword.toLowerCase().includes(query)) {
        filtered.push(kw)
      }
    }
    const grouped: Record<string, Keyword[]> = {}
    for (let i = 0; i < filtered.length; i++) {
      const kw = filtered[i]
      const group = kw.groupName.length > 0 ? kw.groupName : '未分组'
      if (!grouped[group]) {
        grouped[group] = []
      }
      (grouped[group] as Keyword[]).push(kw)
    }
    return grouped
  }

  getTotalCount(): number {
    return this.allKeywords.length
  }

  getUsedCount(): number {
    let count = 0
    for (let i = 0; i < this.allKeywords.length; i++) {
      if (this.allKeywords[i].useCount > 0) {
        count++
      }
    }
    return count
  }

  getUnusedCount(): number {
    return this.getTotalCount() - this.getUsedCount()
  }

  getGroupCount(): number {
    const groups: Record<string, boolean> = {}
    for (let i = 0; i < this.allKeywords.length; i++) {
      const groupName = this.allKeywords[i].groupName.length > 0 ? this.allKeywords[i].groupName : '未分组'
      groups[groupName] = true
    }
    return Object.keys(groups).length
  }

  getGroupUsedCount(keywords: Keyword[]): number {
    let count = 0
    for (let i = 0; i < keywords.length; i++) {
      if (keywords[i].useCount > 0) {
        count++
      }
    }
    return count
  }

  getGroupUseTotal(keywords: Keyword[]): number {
    let count = 0
    for (let i = 0; i < keywords.length; i++) {
      count += keywords[i].useCount
    }
    return count
  }

  private getKeywordStateLabel(keyword: Keyword): string {
    return keyword.useCount > 0 ? '已进入文章流程' : '待带入文章'
  }

  private getKeywordStateHint(keyword: Keyword): string {
    return keyword.useCount > 0
      ? `已带入文章编辑器 ${keyword.useCount} 次，可继续围绕这个关键词补写文章。`
      : '点击"写文章"即可把这个关键词带入文章编辑器，开始新的文章草稿。'
  }

  private getWriteActionLabel(keyword: Keyword): string {
    return keyword.useCount > 0 ? '继续写文章' : '写文章'
  }

  getSelectedCount(): number {
    let count = 0
    for (let i = 0; i < this.selectedFetched.length; i++) {
      if (this.selectedFetched[i]) {
        count++
      }
    }
    return count
  }

  isAllSelected(): boolean {
    if (this.selectedFetched.length === 0) {
      return false
    }
    for (let i = 0; i < this.selectedFetched.length; i++) {
      if (!this.selectedFetched[i]) {
        return false
      }
    }
    return true
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

          if (!this.isLoading && this.allKeywords.length > 0) {
            this.WorkflowSummary()
          }

          // 内容区
          if (this.isLoading) {
            this.LoadingView()
          } else if (this.allKeywords.length === 0) {
            this.EmptyView()
          } else {
            this.GroupList()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BG_PRIMARY)

        // 添加关键词对话框
        if (this.showAddDialog) {
          this.AddKeywordsDialog()
        }

        // AI 获取对话框
        if (this.showFetchDialog) {
          this.FetchKeywordsDialog()
        }

        // 分组删除确认对话框
        if (this.showGroupDeleteConfirm) {
          this.GroupDeleteConfirmDialog()
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
        Text('关键词库')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
        Text(`${this.getUnusedCount()} 个待带入文章 / ${this.getUsedCount()} 个已进入文章流程 / 共 ${this.getTotalCount()} 个关键词`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 操作按钮
      Row({ space: Spacing.SM }) {
        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openAddDialog()
          })

        Button('AI 获取', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.openFetchDialog()
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
      TextInput({ placeholder: '搜索关键词...', text: this.searchQuery })
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
      Text(`待带入文章 ${this.getUnusedCount()} · 已进入文章流程 ${this.getUsedCount()} · 分组 ${this.getGroupCount()}`)
        .fontSize(Typography.CAPTION)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .width('100%')

      Text('关键词会按分组沉淀，并保留带入文章编辑器的次数，方便围绕同一词簇持续补写文章。')
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

      Text('暂无关键词')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('添加关键词来沉淀可带入文章编辑器的内容资产')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.MD }) {
        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openAddDialog()
          })

        Button('AI 获取', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.openFetchDialog()
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
        ForEach(Object.keys(this.getGroupedKeywords()), (groupName: string) => {
          this.GroupCard(groupName, this.getGroupedKeywords()[groupName] as Keyword[])
        }, (groupName: string) => groupName)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  GroupCard(groupName: string, keywords: Keyword[]) {
    Column({ space: Spacing.MD }) {
      // 分组头部
      Row() {
        Row({ space: Spacing.SM }) {
          Text(groupName)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
          Text(`${keywords.length}`)
            .fontSize(Typography.LABEL)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.PRIMARY)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
        .layoutWeight(1)

        // 删除分组按钮
        Button('删除分组', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(Colors.ERROR)
          .onClick(() => {
            this.openGroupDeleteConfirm(groupName)
          })
      }
      .width('100%')

      Text(this.getGroupUsedCount(keywords) > 0
        ? `${this.getGroupUsedCount(keywords)} 个关键词已进入文章流程 · 累计带入编辑器 ${this.getGroupUseTotal(keywords)} 次`
        : '这组关键词还未进入文章流程，可直接从任一关键词开始写文章')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')

      // 关键词资产条目
      Column({ space: Spacing.SM }) {
        ForEach(keywords, (kw: Keyword) => {
          this.KeywordChip(kw)
        }, (kw: Keyword) => kw.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  KeywordChip(kw: Keyword) {
    Column({ space: Spacing.SM }) {
      Row() {
        Text(kw.keyword)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.getKeywordStateLabel(kw))
          .fontSize(Typography.LABEL)
          .fontColor(kw.useCount > 0 ? Colors.SUCCESS : Colors.PRIMARY)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
          .borderRadius(Radius.FULL)
      }
      .width('100%')

      Text(this.getKeywordStateHint(kw))
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')

      Row({ space: Spacing.SM }) {
        Text(kw.useCount > 0 ? `已带入编辑器 ${kw.useCount} 次` : '尚未带入文章编辑器')
          .layoutWeight(1)
          .fontSize(Typography.CAPTION)
          .fontColor(kw.useCount > 0 ? Colors.PRIMARY : Colors.TEXT_HINT)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
          .borderRadius(Radius.FULL)
          .backgroundColor(Colors.BG_SECONDARY)

        Button(this.getWriteActionLabel(kw), { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .backgroundColor(Colors.PRIMARY)
          .onClick(() => {
            this.navigateToEditorFromKeyword(kw)
          })

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .onClick(() => {
            this.handleDeleteKeyword(kw)
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(Colors.BG_PRIMARY)
  }

  // ========== 添加关键词对话框 ==========

  @Builder
  AddKeywordsDialog() {
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
        Text('添加关键词')
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

      // 关键词输入（支持批量）
      Column({ space: Spacing.XS }) {
        Text('关键词')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextArea({ placeholder: '输入关键词，多个用逗号或换行分隔', text: this.formKeywords })
          .height(100)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => {
            this.formKeywords = v
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 分组名称
      Column({ space: Spacing.XS }) {
        Text('分组名称（可选）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：未分组', text: this.formGroupName })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isSubmitting)
          .onChange((v: string) => {
            this.formGroupName = v
          })
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
            this.handleSaveKeywords()
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

  // ========== AI 获取关键词对话框 ==========

  @Builder
  FetchKeywordsDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.isFetching) {
            this.showFetchDialog = false
          }
        })

      // 底部弹窗内容
      Column({ space: Spacing.BASE }) {
      // 标题 + 关闭
      Row() {
        Text('AI 获取关键词')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([Colors.TEXT_HINT])
          .onClick(() => {
            if (!this.isFetching) {
              this.showFetchDialog = false
            }
          })
      }
      .width('100%')

      // 主题/种子关键词
      Column({ space: Spacing.XS }) {
        Text('主题或种子关键词')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '例如：WordPress SEO 优化', text: this.fetchTopic })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isFetching)
          .onChange((v: string) => {
            this.fetchTopic = v
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 数量
      Column({ space: Spacing.XS }) {
        Text('获取数量（5-50）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '20', text: this.fetchCount.toString() })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .type(InputType.Number)
          .enabled(!this.isFetching)
          .onChange((v: string) => {
            const num = parseInt(v)
            if (!isNaN(num) && num >= 5 && num <= 50) {
              this.fetchCount = num
            }
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 分组名称
      Column({ space: Spacing.XS }) {
        Text('分组名称（可选）')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：未分组', text: this.fetchGroupName })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(Colors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(Colors.TEXT_PRIMARY)
          .placeholderColor(Colors.TEXT_HINT)
          .enabled(!this.isFetching)
          .onChange((v: string) => {
            this.fetchGroupName = v
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 开始获取按钮
      Button(this.isFetching ? '获取中...' : '开始获取', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isFetching && this.fetchTopic.trim().length > 0)
        .onClick(() => {
          this.handleFetchFromAI()
        })

      // 获取结果区域
      if (this.fetchedKeywords.length > 0) {
        Column({ space: Spacing.SM }) {
          // 标题 + 全选
          Row() {
            Text(`已获取 ${this.fetchedKeywords.length} 个关键词`)
              .fontSize(Typography.BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor(Colors.TEXT_PRIMARY)
              .layoutWeight(1)

            Button(this.isAllSelected() ? '取消全选' : '全选', { type: ButtonType.Normal })
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.PRIMARY)
              .backgroundColor(Color.Transparent)
              .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
              .onClick(() => {
                const selectAll = !this.isAllSelected()
                const newSelected: boolean[] = []
                for (let i = 0; i < this.selectedFetched.length; i++) {
                  newSelected.push(selectAll)
                }
                this.selectedFetched = newSelected
              })
          }
          .width('100%')

          // 可选关键词标签
          Scroll() {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.fetchedKeywords, (kw: string, index: number) => {
                Text(kw)
                  .fontSize(Typography.BODY)
                  .fontColor(this.selectedFetched[index] ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
                  .backgroundColor(this.selectedFetched[index] ? Colors.PRIMARY : Colors.BG_SECONDARY)
                  .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                  .borderRadius(Radius.FULL)
                  .borderWidth(1)
                  .borderColor(this.selectedFetched[index] ? Colors.PRIMARY : Colors.BORDER)
                  .margin({ right: Spacing.SM, bottom: Spacing.SM })
                  .onClick(() => {
                    const updated: boolean[] = []
                    for (let j = 0; j < this.selectedFetched.length; j++) {
                      if (j === index) {
                        updated.push(!this.selectedFetched[j])
                      } else {
                        updated.push(this.selectedFetched[j])
                      }
                    }
                    this.selectedFetched = updated
                  })
              }, (kw: string, index: number) => `${kw}_${index}`)
            }
            .width('100%')
          }
          .constraintSize({ maxHeight: 160 })
          .scrollBar(BarState.Off)

          // 添加选中的关键词
          Button(`添加 ${this.getSelectedCount()} 个关键词`, { type: ButtonType.Capsule })
            .width('100%')
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(this.getSelectedCount() > 0 ? Colors.PRIMARY : Colors.PRIMARY_DISABLED)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .enabled(this.getSelectedCount() > 0 && !this.isSubmitting)
            .onClick(() => {
              this.handleSaveFetched()
            })
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
    .translate({ y: this.showFetchDialog ? '-100%' : '0' })
    .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 分组删除确认对话框 ==========

  @Builder
  GroupDeleteConfirmDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .onClick(() => {
          if (!this.isDeletingGroup) {
            this.showGroupDeleteConfirm = false
          }
        })

      // 弹窗内容
      Column({ space: Spacing.BASE }) {
        // 标题
        Text('确认删除分组')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .width('100%')

        // 确认信息
        Text(`确定删除分组「${this.groupToDelete}」下的所有关键词吗？`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .width('100%')

        // 警告信息
        Text('此操作不可撤销，分组下的所有关键词将被永久删除。')
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.ERROR)
          .width('100%')

        // 操作按钮
        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(Colors.TEXT_PRIMARY)
            .backgroundColor(Colors.BG_SECONDARY)
            .enabled(!this.isDeletingGroup)
            .onClick(() => {
              this.showGroupDeleteConfirm = false
            })

          Button(this.isDeletingGroup ? '删除中...' : '确认删除', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(Colors.ERROR)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.isDeletingGroup)
            .onClick(() => {
              this.handleDeleteGroup()
            })
        }
        .width('100%')
        .margin({ top: Spacing.SM })
      }
      .width('90%')
      .constraintSize({ maxWidth: 400 })
      .padding(Spacing.LG)
      .borderRadius(Radius.LG)
      .backgroundColor(Colors.BG_PRIMARY)
      .shadow({ radius: 10, color: '#40000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 业务逻辑 ==========

  private async loadKeywords(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      this.allKeywords = await KeywordDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load keywords failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载关键词失败' })
    } finally {
      this.isLoading = false
    }
  }

  private openAddDialog(): void {
    this.formKeywords = ''
    this.formGroupName = ''
    this.showAddDialog = true
  }

  private openFetchDialog(): void {
    this.fetchTopic = ''
    this.fetchCount = 20
    this.fetchGroupName = ''
    this.fetchedKeywords = []
    this.selectedFetched = []
    this.showFetchDialog = true
  }

  private async handleSaveKeywords(): Promise<void> {
    if (this.formKeywords.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入关键词' })
      return
    }

    this.isSubmitting = true
    try {
      // Split by comma (English/Chinese) or newline
      const rawKeywords = this.formKeywords.split(/[,，\n]+/)
      const keywords: string[] = []
      for (let i = 0; i < rawKeywords.length; i++) {
        const trimmed = rawKeywords[i].trim()
        if (trimmed.length > 0) {
          keywords.push(trimmed)
        }
      }

      if (keywords.length === 0) {
        UiFeedback.showToast({ message: '请输入有效的关键词' })
        this.isSubmitting = false
        return
      }

      // Get existing keywords for deduplication
      const existingKeywords = await KeywordDao.findByUserId(this.currentUserId)
      const existingSet: Record<string, boolean> = {}
      for (let i = 0; i < existingKeywords.length; i++) {
        existingSet[existingKeywords[i].keyword.toLowerCase()] = true
      }

      let created = 0
      let skipped = 0
      const groupName = this.formGroupName.trim().length > 0 ? this.formGroupName.trim() : ''

      for (let i = 0; i < keywords.length; i++) {
        const kw = keywords[i]
        if (existingSet[kw.toLowerCase()] !== undefined) {
          skipped++
        } else {
          await KeywordDao.insert(this.currentUserId, kw, groupName)
          existingSet[kw.toLowerCase()] = true
          created++
        }
      }

      if (keywords.length === 1) {
        UiFeedback.showToast({ message: '关键词已添加', duration: 2000 })
      } else {
        UiFeedback.showToast({ message: `导入 ${created} 个关键词，跳过 ${skipped} 个重复`, duration: 2000 })
      }
      this.showAddDialog = false
      this.formKeywords = ''
      this.formGroupName = ''
      await this.loadKeywords()
    } catch (err) {
      Logger.error('Save keywords failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '添加关键词失败' })
    } finally {
      this.isSubmitting = false
    }
  }

  private async handleFetchFromAI(): Promise<void> {
    if (this.fetchTopic.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入主题或种子关键词' })
      return
    }

    this.isFetching = true
    try {
      const aiSettings = await AISettingsDao.findDefault(this.currentUserId)
      if (aiSettings === null) {
      UiFeedback.showToast({ message: '请先配置 AI 设置' })
        this.isFetching = false
        return
      }

      if (aiSettings.apiEndpoint.length === 0 || aiSettings.apiKey.length === 0) {
      UiFeedback.showToast({ message: 'AI 配置不完整，请检查 API 端点和密钥' })
        this.isFetching = false
        return
      }

      // 构建 prompt
      const prompt = `请根据主题"${this.fetchTopic.trim()}"生成 ${this.fetchCount} 个相关的 SEO 关键词。
要求：
1. 关键词与主题高度相关
2. 包含长尾关键词和短关键词
3. 直接输出关键词列表，用英文逗号分隔
4. 不要有序号、解释或其他多余内容
5. 每个关键词简洁精准`

      const messages: ChatMessage[] = []
      const msg = new ChatMessage()
      msg.role = 'user'
      msg.content = prompt
      messages.push(msg)

      // 确保端点格式正确
      let endpoint = aiSettings.apiEndpoint
      if (!endpoint.includes('/chat/completions') && !endpoint.includes('/v1/')) {
        endpoint = endpoint.replace(/\/$/, '') + '/chat/completions'
      }

      const result = await AIStreamClient.sendOnce(endpoint, aiSettings.apiKey, aiSettings.model, messages)

      if (result.length === 0) {
      UiFeedback.showToast({ message: 'AI 未返回结果，请重试' })
        this.isFetching = false
        return
      }

      // 解析逗号分隔的关键词
      const rawKeywords = result.split(/[,，]/)
      const parsed: string[] = []
      const initSelected: boolean[] = []
      for (let i = 0; i < rawKeywords.length; i++) {
        const kw = rawKeywords[i].trim().replace(/^["'`\d.、\s]+|["'`\s]+$/g, '')
        if (kw.length > 0) {
          parsed.push(kw)
          initSelected.push(true)
        }
      }

      this.fetchedKeywords = parsed
      this.selectedFetched = initSelected
      UiFeedback.showToast({ message: `成功获取 ${parsed.length} 个关键词`, duration: 2000 })
    } catch (err) {
      Logger.error('Fetch keywords from AI failed: %{public}s', String(err))
      UiFeedback.showToast({ message: 'AI 获取失败，请检查网络和配置' })
    } finally {
      this.isFetching = false
    }
  }

  private async handleSaveFetched(): Promise<void> {
    this.isSubmitting = true
    try {
      // Get existing keywords for deduplication
      const existingKeywords = await KeywordDao.findByUserId(this.currentUserId)
      const existingSet: Record<string, boolean> = {}
      for (let i = 0; i < existingKeywords.length; i++) {
        existingSet[existingKeywords[i].keyword.toLowerCase()] = true
      }

      let created = 0
      let skipped = 0
      const groupName = this.fetchGroupName.trim().length > 0 ? this.fetchGroupName.trim() : this.fetchTopic.trim()

      for (let i = 0; i < this.fetchedKeywords.length; i++) {
        if (this.selectedFetched[i]) {
          const kw = this.fetchedKeywords[i]
          if (existingSet[kw.toLowerCase()] !== undefined) {
            skipped++
          } else {
            await KeywordDao.insert(this.currentUserId, kw, groupName)
            existingSet[kw.toLowerCase()] = true
            created++
          }
        }
      }

      UiFeedback.showToast({ message: `保存成功：新增 ${created} 个，跳过 ${skipped} 个重复关键词`, duration: 2000 })
      this.showFetchDialog = false
      this.fetchedKeywords = []
      this.selectedFetched = []
      await this.loadKeywords()
    } catch (err) {
      Logger.error('Save fetched keywords failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '保存失败' })
    } finally {
      this.isSubmitting = false
    }
  }

  private async handleDeleteKeyword(kw: Keyword): Promise<void> {
    try {
      await KeywordDao.deleteById(kw.id)
      UiFeedback.showToast({ message: `已删除"${kw.keyword}"`, duration: 2000 })
      await this.loadKeywords()
    } catch (err) {
      Logger.error('Delete keyword failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }

  private async navigateToEditorFromKeyword(kw: Keyword): Promise<void> {
    try {
      await KeywordDao.incrementUseCount(kw.id)
      this.syncKeywordUseCount(kw.id)
      UiFeedback.showToast({ message: `"${kw.keyword}" 已带入文章编辑器`, duration: 1500 })
    } catch (err) {
      Logger.error('Increment keyword use count failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '状态更新失败，仍将打开编辑器' })
    }

    const param: Record<string, string> = {}
    param['articleId'] = 'new'
    param['sourceType'] = 'keyword'
    param['sourceId'] = kw.id
    param['initialTitle'] = ''
    param['initialKeywords'] = kw.keyword
    this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
  }

  private syncKeywordUseCount(keywordId: string): void {
    const nextKeywords: Keyword[] = []
    for (let i = 0; i < this.allKeywords.length; i++) {
      const current = this.allKeywords[i]
      if (current.id === keywordId) {
        current.useCount = current.useCount + 1
      }
      nextKeywords.push(current)
    }
    this.allKeywords = nextKeywords
  }

  private openGroupDeleteConfirm(groupName: string): void {
    this.groupToDelete = groupName
    this.showGroupDeleteConfirm = true
  }

  private async handleDeleteGroup(): Promise<void> {
    if (this.groupToDelete.length === 0) {
      this.showGroupDeleteConfirm = false
      return
    }

    this.isDeletingGroup = true
    try {
      const keywordsInGroup = await KeywordDao.findByGroup(this.currentUserId, this.groupToDelete)
      let deletedCount = 0
      for (let i = 0; i < keywordsInGroup.length; i++) {
        await KeywordDao.deleteById(keywordsInGroup[i].id)
        deletedCount++
      }
      UiFeedback.showToast({ message: `已删除 ${deletedCount} 个关键词`, duration: 2000 })
      this.showGroupDeleteConfirm = false
      this.groupToDelete = ''
      await this.loadKeywords()
    } catch (err) {
      Logger.error('Delete group failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除分组失败' })
    } finally {
      this.isDeletingGroup = false
    }
  }
}
