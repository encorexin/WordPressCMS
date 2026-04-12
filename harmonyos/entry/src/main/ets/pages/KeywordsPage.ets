// 关键词管理页面 — 对标 React Keywords.tsx

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes, ArticleEditorNavParam } from '../constants/Routes'
import { Keyword } from '../models/Keyword'
import { KeywordDao } from '../services/db/KeywordDao'
import { AIStreamClient, ChatMessage } from '../services/http/AIStreamClient'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { BasicDataSource } from '../utils/BasicDataSource'
import { KeywordAddDialogComponent } from '../components/keyword/KeywordAddDialog'
import { KeywordGroupDeleteDialogComponent } from '../components/keyword/KeywordGroupDeleteDialog'
import { KeywordHeaderPanelComponent } from '../components/keyword/KeywordHeaderPanel'
import { KeywordGroupListComponent, KeywordGroupViewModel } from '../components/keyword/KeywordGroupList'
import { AppStorageKeys } from '../constants/AppStorageKeys'

@Component
export struct KeywordsPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''

  // 数据
  @State @Watch('refreshGroupDataSource') allKeywords: Keyword[] = []
  @State @Watch('refreshGroupDataSource') searchQuery: string = ''
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
  private groupDataSource: BasicDataSource<KeywordGroupViewModel> = new BasicDataSource<KeywordGroupViewModel>([])

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

  private refreshGroupDataSource(): void {
    const grouped = this.getGroupedKeywords()
    const groupNames = Object.keys(grouped)
    const data: KeywordGroupViewModel[] = []
    for (let i = 0; i < groupNames.length; i++) {
      const item = new KeywordGroupViewModel()
      item.groupName = groupNames[i]
      item.keywords = grouped[groupNames[i]] as Keyword[]
      for (let j = 0; j < item.keywords.length; j++) {
        const keyword = item.keywords[j]
        if (keyword.useCount > 0) {
          item.usedCount += 1
        }
        item.useTotal += keyword.useCount
      }
      data.push(item)
    }
    this.groupDataSource.setData(data)
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
          KeywordHeaderPanelComponent({
            searchQuery: $searchQuery,
            unusedCount: this.getUnusedCount(),
            usedCount: this.getUsedCount(),
            totalCount: this.getTotalCount(),
            groupCount: this.getGroupCount(),
            showSummary: !this.isLoading && this.allKeywords.length > 0,
            onOpenAdd: () => {
              this.openAddDialog()
            },
            onOpenFetch: () => {
              this.openFetchDialog()
            }
          })

          // 内容区
          if (this.isLoading) {
            this.LoadingView()
          } else if (this.allKeywords.length === 0) {
            this.EmptyView()
          } else {
            KeywordGroupListComponent({
              dataSource: this.groupDataSource,
              onDeleteGroup: (groupName: string) => {
                this.openGroupDeleteConfirm(groupName)
              },
              onWrite: (keyword: Keyword) => {
                this.navigateToEditorFromKeyword(keyword)
              },
              onDeleteKeyword: (keyword: Keyword) => {
                this.handleDeleteKeyword(keyword)
              }
            })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.BG_PRIMARY)

          // 添加关键词对话框
        if (this.showAddDialog) {
          KeywordAddDialogComponent({
            isVisible: this.showAddDialog,
            formKeywords: $formKeywords,
            formGroupName: $formGroupName,
            isSubmitting: this.isSubmitting,
            onClose: () => {
              this.showAddDialog = false
            },
            onSubmit: () => {
              this.handleSaveKeywords()
            }
          })
        }

        // AI 获取对话框
        if (this.showFetchDialog) {
          this.FetchKeywordsDialog()
        }

        // 分组删除确认对话框
        if (this.showGroupDeleteConfirm) {
          KeywordGroupDeleteDialogComponent({
            groupName: this.groupToDelete,
            isDeleting: this.isDeletingGroup,
            onClose: () => {
              this.showGroupDeleteConfirm = false
            },
            onConfirm: () => {
              this.handleDeleteGroup()
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== 加载中 ==========

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(ResourceColors.PRIMARY)
      Text('加载中...')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_HINT)
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
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无关键词')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text('添加关键词来沉淀可带入文章编辑器的内容资产')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.MD }) {
        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(ResourceColors.PRIMARY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openAddDialog()
          })

        Button('AI 获取', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(ResourceColors.BORDER)
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

  // ========== AI 获取关键词对话框 ==========

  @Builder
  FetchKeywordsDialog() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
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
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([ResourceColors.TEXT_HINT])
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
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '例如：WordPress SEO 优化', text: this.fetchTopic })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
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
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '20', text: this.fetchCount.toString() })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
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
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '默认：未分组', text: this.fetchGroupName })
          .height(ComponentSize.INPUT_HEIGHT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
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
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
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
              .fontColor(ResourceColors.TEXT_PRIMARY)
              .layoutWeight(1)

            Button(this.isAllSelected() ? '取消全选' : '全选', { type: ButtonType.Normal })
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.PRIMARY)
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
                  .fontColor(this.selectedFetched[index] ? ResourceColors.TEXT_ON_PRIMARY : ResourceColors.TEXT_PRIMARY)
                  .backgroundColor(this.selectedFetched[index] ? ResourceColors.PRIMARY : ResourceColors.BG_SECONDARY)
                  .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.XS, bottom: Spacing.XS })
                  .borderRadius(Radius.FULL)
                  .borderWidth(1)
                  .borderColor(this.selectedFetched[index] ? ResourceColors.PRIMARY : ResourceColors.BORDER)
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
            .backgroundColor(this.getSelectedCount() > 0 ? ResourceColors.PRIMARY : ResourceColors.PRIMARY_DISABLED)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
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
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .position({ x: 0, y: '100%' })
    .translate({ y: this.showFetchDialog ? '-100%' : '0' })
    .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }

  // ========== 业务逻辑 ==========

  private async loadKeywords(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.allKeywords = []
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

    const param = new ArticleEditorNavParam()
    param.articleId = 'new'
    param.sourceType = 'keyword'
    param.sourceId = kw.id
    param.initialTitle = ''
    param.initialKeywords = kw.keyword
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
