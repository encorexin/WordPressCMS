// 文章列表管理页面 — 支持搜索、状态筛选、站点筛选和批量操作

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { Article } from '../models/Article'
import { WordPressSite } from '../models/WordPressSite'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { VersionDao } from '../services/db/VersionDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { formatDateTime } from '../utils/DateUtil'
import pasteboard from '@ohos.pasteboard'

@Component
export struct ArticlesPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  @State articles: Article[] = []
  @State sites: WordPressSite[] = []
  @State searchQuery: string = ''
  @State filterStatus: string = 'all'
  @State selectedSiteId: string = ''
  @State isLoading: boolean = true
  @State batchMode: boolean = false
  @State selectedIds: string[] = []
  @State showBatchDeleteConfirm: boolean = false
  @StorageProp('articlesNeedRefresh') @Watch('onArticlesNeedRefresh') articlesNeedRefresh: number = 0

  // 状态筛选选项
  private filterOptions: string[] = ['all', 'draft', 'published', 'pending']
  private filterLabels: Record<string, string> = {
    'all': '全部',
    'draft': '草稿',
    'published': '已发布',
    'pending': '待处理'
  }

  aboutToAppear(): void {
    this.loadArticles()
    this.loadSites()
  }

  onArticlesNeedRefresh(): void {
    this.loadArticles()
  }

  // ========== 计算属性 ==========

  private getNormalizedQuery(): string {
    return this.searchQuery.trim().toLowerCase()
  }

  private matchesSearch(article: Article): boolean {
    const query = this.getNormalizedQuery()
    if (query.length === 0) {
      return true
    }
    return article.title.toLowerCase().includes(query) || article.keywords.toLowerCase().includes(query)
  }

  private matchesStatus(article: Article): boolean {
    return this.filterStatus === 'all' || article.status === this.filterStatus
  }

  private matchesSite(article: Article): boolean {
    return this.selectedSiteId.length === 0 || article.siteId === this.selectedSiteId
  }

  getFilteredArticles(): Article[] {
    return this.articles.filter((article: Article) =>
      this.matchesStatus(article) && this.matchesSearch(article) && this.matchesSite(article))
  }

  private getStatusCount(status: string): number {
    if (status === 'all') {
      return this.articles.length
    }
    return this.articles.filter((article: Article) => article.status === status).length
  }

  private getActiveScopeLabel(): string {
    let label = this.filterStatus === 'all' ? '全部文章' : this.filterLabels[this.filterStatus]
    const query = this.searchQuery.trim()
    if (query.length > 0) {
      label = `${label} · “${query}”`
    }
    return label
  }

  private getResultSummary(): string {
    const visibleCount = this.getFilteredArticles().length
    if (this.articles.length === 0) {
      return '这里集中管理文章草稿、待处理和已发布内容，也承接从主题与关键词带入的文章'
    }
    if (this.filterStatus === 'all' && this.getNormalizedQuery().length === 0) {
      return `共 ${visibleCount} 篇文章，可按标题或关键词快速查找`
    }
    return `当前显示 ${visibleCount} 篇 · ${this.getActiveScopeLabel()}`
  }

  private getNoResultsTitle(): string {
    return this.getNormalizedQuery().length > 0 ? '没有找到匹配文章' : '当前筛选暂无文章'
  }

  private getNoResultsDescription(): string {
    const query = this.searchQuery.trim()
    if (query.length > 0 && this.filterStatus !== 'all') {
      return `没有在${this.filterLabels[this.filterStatus]}中找到“${query}”，请尝试调整搜索词或查看全部文章`
    }
    if (query.length > 0) {
      return `标题或关键词中没有匹配“${query}”的文章`
    }
    return `当前没有${this.filterLabels[this.filterStatus]}文章，请切换状态查看其他内容`
  }

  private resetViewState(): void {
    this.searchQuery = ''
    this.filterStatus = 'all'
    this.selectedSiteId = ''
    this.batchMode = false
    this.selectedIds = []
  }

  private getSiteName(siteId: string): string {
    if (siteId.length === 0) {
      return ''
    }
    for (const site of this.sites) {
      if (site.id === siteId) {
        return site.siteName
      }
    }
    return ''
  }

  private getSiteSelectOptions(): SelectOption[] {
    const options: SelectOption[] = []
    const allOpt: SelectOption = { value: '全部站点' }
    options.push(allOpt)
    for (const site of this.sites) {
      const opt: SelectOption = { value: site.siteName }
      options.push(opt)
    }
    return options
  }

  private getSiteUrl(siteId: string): string {
    if (siteId.length === 0) {
      return ''
    }
    for (const site of this.sites) {
      if (site.id === siteId) {
        return site.siteUrl
      }
    }
    return ''
  }

  private getContentExcerpt(content: string): string {
    const plainText = content.replace(/[#*_\[\]()]/g, '').replace(/\n/g, ' ').trim()
    if (plainText.length <= 100) {
      return plainText
    }
    return plainText.substring(0, 100) + '...'
  }

  private isSelected(articleId: string): boolean {
    for (const id of this.selectedIds) {
      if (id === articleId) {
        return true
      }
    }
    return false
  }

  private toggleSelection(articleId: string): void {
    const index = this.selectedIds.indexOf(articleId)
    if (index >= 0) {
      this.selectedIds.splice(index, 1)
    } else {
      this.selectedIds.push(articleId)
    }
  }

  private selectAll(): void {
    const filtered = this.getFilteredArticles()
    this.selectedIds = []
    for (const article of filtered) {
      this.selectedIds.push(article.id)
    }
  }

  private deselectAll(): void {
    this.selectedIds = []
  }

  private isAllSelected(): boolean {
    const filtered = this.getFilteredArticles()
    if (filtered.length === 0) {
      return false
    }
    for (const article of filtered) {
      let found = false
      for (const id of this.selectedIds) {
        if (id === article.id) {
          found = true
          break
        }
      }
      if (!found) {
        return false
      }
    }
    return true
  }

  private copyToClipboard(text: string): void {
    try {
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      pasteboard.getSystemPasteboard().setData(pasteboardData)
      UiFeedback.showToast({ message: '链接已复制' })
    } catch (err) {
      Logger.error('Copy to clipboard failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '复制失败' })
    }
  }

  // ========== 构建 UI ==========

  build() {
    Column() {
      // 页面标题
      this.HeaderArea()

      // 筛选标签栏
      this.FilterTabs()

      // 站点筛选下拉框
      if (this.sites.length > 0) {
        this.SiteFilter()
      }

      // 批量操作工具栏
      if (this.batchMode && this.getFilteredArticles().length > 0) {
        this.BatchToolbar()
      }

      // 搜索栏
      this.SearchBar()

      if (!this.isLoading) {
        this.ResultsSummary()
      }

      // 内容区
      if (this.isLoading) {
        this.LoadingView()
      } else if (this.articles.length === 0) {
        this.EmptyView()
      } else if (this.getFilteredArticles().length === 0) {
        this.NoResultsView()
      } else {
        this.ArticleList()
      }

      // 批量删除确认对话框
      if (this.showBatchDeleteConfirm) {
        this.BatchDeleteConfirmDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BG_PRIMARY)
  }

  // ========== 页面标题 ==========

  @Builder
  HeaderArea() {
    Row() {
      Column({ space: Spacing.XS }) {
        Text('文章管理')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
        Text(`共 ${this.articles.length} 篇 · 草稿 ${this.getStatusCount('draft')} · 待处理 ${this.getStatusCount('pending')} · 已发布 ${this.getStatusCount('published')}`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.articles.length > 0) {
        Button(this.batchMode ? '退出批量' : '批量操作', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontColor(this.batchMode ? Colors.TEXT_ON_PRIMARY : Colors.PRIMARY)
          .backgroundColor(this.batchMode ? Colors.PRIMARY : Colors.BG_SECONDARY)
          .fontSize(Typography.BODY)
          .margin({ right: Spacing.SM })
          .onClick(() => {
            this.batchMode = !this.batchMode
            this.selectedIds = []
          })
      }

      Button('新建文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.navigateToEditor('new')
        })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 站点筛选 ==========

  @Builder
  SiteFilter() {
    Row({ space: Spacing.SM }) {
      Text('按站点筛选:')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)

      Select(this.getSiteSelectOptions())
        .selected(this.selectedSiteId.length > 0 ? this.getSelectedSiteIndex() : 0)
        .value(this.selectedSiteId.length > 0 ? this.getSiteName(this.selectedSiteId) : '全部站点')
        .font({ size: Typography.BODY, weight: FontWeight.Medium })
        .fontColor(Colors.TEXT_PRIMARY)
        .backgroundColor(Colors.BG_SECONDARY)
        .optionFont({ size: Typography.BODY })
        .optionBgColor(Colors.BG_PRIMARY)
        .onSelect((index: number) => {
          if (index === 0) {
            this.selectedSiteId = ''
          } else {
            this.selectedSiteId = this.sites[index - 1].id
          }
        })
        .layoutWeight(1)

      if (this.selectedSiteId.length > 0) {
        Button('清除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.selectedSiteId = ''
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
    .alignItems(VerticalAlign.Center)
  }

  private getSelectedSiteIndex(): number {
    for (let i = 0; i < this.sites.length; i++) {
      if (this.sites[i].id === this.selectedSiteId) {
        return i + 1
      }
    }
    return 0
  }

  // ========== 批量操作工具栏 ==========

  @Builder
  BatchToolbar() {
    Row({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Checkbox()
          .select(this.isAllSelected())
          .selectedColor(Colors.PRIMARY)
          .onChange((value: boolean) => {
            if (value) {
              this.selectAll()
            } else {
              this.deselectAll()
            }
          })

        Text(`全选 (${this.selectedIds.length}/${this.getFilteredArticles().length})`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
      }
      .layoutWeight(1)

      Button('删除选中', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .backgroundColor(Colors.ERROR)
        .enabled(this.selectedIds.length > 0)
        .onClick(() => {
          this.showBatchDeleteConfirm = true
        })
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.MD)
    .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
  }

  // ========== 筛选标签栏 ==========

  @Builder
  FilterTabs() {
    Row({ space: Spacing.SM }) {
      ForEach(this.filterOptions, (status: string) => {
        Button(this.filterLabels[status], { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(this.filterStatus === status ? Colors.TEXT_ON_PRIMARY : Colors.TEXT_PRIMARY)
          .backgroundColor(this.filterStatus === status ? Colors.PRIMARY : Colors.BG_SECONDARY)
          .padding({ left: Spacing.MD, right: Spacing.MD })
          .onClick(() => {
            this.filterStatus = status
          })
      }, (status: string) => status)
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.BASE, bottom: Spacing.SM })
  }

  // ========== 搜索栏 ==========

  @Builder
  SearchBar() {
    Row() {
      // 搜索图标
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.TEXT_HINT])
        .margin({ left: Spacing.MD })

      // 输入框
      TextInput({ placeholder: '搜索标题或关键词...', text: this.searchQuery })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Color.Transparent)
        .padding({ left: Spacing.SM, right: Spacing.BASE })
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_PRIMARY)
        .placeholderColor(Colors.TEXT_HINT)
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchQuery = value
        })

      // 清除按钮
      if (this.searchQuery.length > 0) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([Colors.TEXT_HINT])
          .margin({ right: Spacing.MD })
          .onClick(() => {
            this.searchQuery = ''
          })
      }
    }
    .width('100%')
    .height(ComponentSize.INPUT_HEIGHT)
    .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.BASE })
    .borderRadius(Radius.FULL)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  ResultsSummary() {
    Row({ space: Spacing.SM }) {
      Text(this.getResultSummary())
        .layoutWeight(1)
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)

      if (this.searchQuery.trim().length > 0 || this.filterStatus !== 'all' || this.selectedSiteId.length > 0) {
        Button('重置条件', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.resetViewState()
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
    .alignItems(VerticalAlign.Center)
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
      SymbolGlyph($r('sys.symbol.doc_filled_on_doc'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无文章')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('可直接新建文章，也可以从主题或关键词带入文章草稿；进入后的内容会在这里继续管理')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('新建文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.navigateToEditor('new')
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 无搜索结果 ==========

  @Builder
  NoResultsView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text(this.getNoResultsTitle())
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text(this.getNoResultsDescription())
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('查看全部文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .fontColor(Colors.PRIMARY)
        .backgroundColor('transparent')
        .borderWidth(1)
        .borderColor(Colors.BORDER)
        .fontSize(Typography.BODY)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.resetViewState()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 批量删除确认对话框 ==========

  @Builder
  BatchDeleteConfirmDialog() {
    Column() {
      Column({ space: Spacing.MD }) {
        Text('确认批量删除')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        Text(`确定要删除选中的 ${this.selectedIds.length} 篇文章吗？此操作无法撤销。`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)

        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_PRIMARY)
            .backgroundColor(Colors.BG_SECONDARY)
            .onClick(() => {
              this.showBatchDeleteConfirm = false
            })

          Button('删除', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(Colors.ERROR)
            .onClick(() => {
              this.showBatchDeleteConfirm = false
              this.handleBatchDelete()
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.LG)
      .backgroundColor(Colors.BG_PRIMARY)
      .borderRadius(Radius.LG)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .onClick(() => {
      this.showBatchDeleteConfirm = false
    })
  }

  // ========== 文章列表 ==========

  @Builder
  ArticleList() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Scroll() {
        Column({ space: Spacing.MD }) {
          ForEach(this.getFilteredArticles(), (article: Article) => {
            this.ArticleCard(article)
          }, (article: Article) => article.id)
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: 100 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 悬浮按钮 — 新建文章（批量模式下隐藏）
      if (!this.batchMode) {
        Button({ type: ButtonType.Circle }) {
          Row({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.square_and_pencil'))
              .fontSize(ComponentSize.ICON_MD)
              .fontColor([Colors.TEXT_ON_PRIMARY])
            Text('新建文章')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_ON_PRIMARY)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: Spacing.MD, right: Spacing.MD })
        }
        .width('auto')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .margin({ right: Spacing.BASE, bottom: Spacing.BASE })
        .onClick(() => {
          this.navigateToEditor('new')
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  ArticleCard(article: Article) {
    Column({ space: Spacing.MD }) {
      Column({ space: Spacing.MD }) {
        Row() {
          if (this.batchMode) {
            Checkbox()
              .select(this.isSelected(article.id))
              .selectedColor(Colors.PRIMARY)
              .margin({ right: Spacing.SM })
              .onChange((value: boolean) => {
                this.toggleSelection(article.id)
              })
          }

          Text(article.title.length > 0 ? article.title : '无标题')
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Text(this.getStatusLabel(article.status))
            .fontSize(Typography.LABEL)
            .fontColor(this.getStatusColor(article.status))
            .backgroundColor(this.getStatusBgColor(article.status))
            .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
            .borderRadius(Radius.FULL)
            .margin({ left: Spacing.SM })
        }
        .width('100%')

        if (article.content.length > 0) {
          Text(this.getContentExcerpt(article.content))
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_SECONDARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        this.ArticleMetaRow(article)
      }
      .width('100%')
      .onClick(() => {
        if (!this.batchMode) {
          this.navigateToEditor(article.id)
        } else {
          this.toggleSelection(article.id)
        }
      })

      this.ArticleActionRow(article)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  ArticleMetaRow(article: Article) {
    Row({ space: Spacing.SM }) {
      this.SiteLabel(article.siteId)

      if (article.keywords.length > 0) {
        Row({ space: 4 }) {
          Text('关键词:')
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_HINT)
            .flexShrink(0)
          Text(article.keywords)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
        .borderRadius(Radius.SM)
        .backgroundColor(Colors.BG_PRIMARY)
        .layoutWeight(1)
      } else {
        Blank().layoutWeight(1)
      }

      Text(formatDateTime(article.createdAt))
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_HINT)
        .flexShrink(0)
    }
    .width('100%')
  }

  @Builder
  SiteLabel(siteId: string) {
    if (this.getSiteName(siteId).length > 0) {
      Text(this.getSiteName(siteId))
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.PRIMARY)
        .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
        .borderRadius(Radius.SM)
        .backgroundColor(Colors.BG_PRIMARY)
    } else {
      Text('未关联站点')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_HINT)
        .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
        .borderRadius(Radius.SM)
        .backgroundColor(Colors.BG_PRIMARY)
    }
  }

  @Builder
  ArticleActionRow(article: Article) {
    Row({ space: Spacing.SM }) {
      Button(this.batchMode ? '查看详情' : this.getPrimaryActionLabel(article.status), { type: ButtonType.Capsule })
        .layoutWeight(1)
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.navigateToEditor(article.id)
        })

      if (article.status === 'published' && article.wordpressPostId.length > 0) {
        Button('预览', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(Colors.PRIMARY)
          .onClick(() => {
            this.handlePreview(article)
          })
      }

      Button('删除', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .fontSize(Typography.BODY)
        .fontColor(Colors.ERROR)
        .backgroundColor(Color.Transparent)
        .borderWidth(1)
        .borderColor(Colors.BORDER)
        .onClick(() => {
          this.confirmDeleteArticle(article)
        })
    }
    .width('100%')
  }

  // ========== 业务逻辑 ==========

  private async loadArticles(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.articles = []
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      this.articles = await ArticleDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load articles failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载文章失败' })
    } finally {
      this.isLoading = false
    }
  }

  private async loadSites(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.sites = []
      return
    }
    try {
      this.sites = await SiteDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load sites failed: %{public}s', String(err))
    }
  }

  private navigateToEditor(articleId: string): void {
    const param: Record<string, string> = {}
    param['articleId'] = articleId.length > 0 ? articleId : 'new'
    param['sourceType'] = 'article'
    param['sourceId'] = ''
    param['initialTitle'] = ''
    param['initialKeywords'] = ''
    this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
  }

  private confirmDeleteArticle(article: Article): void {
    UiFeedback.showConfirm({
      title: '确认删除',
      message: `确定要删除文章"${article.title || '无标题'}"吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: Colors.ERROR,
        action: () => {
          this.handleDeleteArticle(article.id)
        }
      }
    })
  }

  private async handleDeleteArticle(id: string): Promise<void> {
    try {
      await VersionDao.deleteByArticleId(id)
      await ArticleDao.deleteById(id)
      UiFeedback.showToast({ message: '已删除文章', duration: 2000 })
      await this.loadArticles()
    } catch (err) {
      Logger.error('Delete article failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }

  private async handleBatchDelete(): Promise<void> {
    if (this.selectedIds.length === 0) {
      UiFeedback.showToast({ message: '请先选择要删除的文章' })
      return
    }
    try {
      for (const id of this.selectedIds) {
        await VersionDao.deleteByArticleId(id)
        await ArticleDao.deleteById(id)
      }
      UiFeedback.showToast({ message: `已删除 ${this.selectedIds.length} 篇文章`, duration: 2000 })
      this.selectedIds = []
      this.batchMode = false
      await this.loadArticles()
    } catch (err) {
      Logger.error('Batch delete articles failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '批量删除失败' })
    }
  }

  private handlePreview(article: Article): void {
    const siteUrl: string = this.getSiteUrl(article.siteId)
    if (siteUrl.length > 0 && article.wordpressPostId.length > 0) {
      const cleanUrl: string = siteUrl.replace(/\/$/, '')
      const previewUrl: string = `${cleanUrl}/?p=${article.wordpressPostId}`
      this.copyToClipboard(previewUrl)
    } else {
      UiFeedback.showToast({ message: '该文章尚未发布到WordPress' })
    }
  }

  private getStatusLabel(status: string): string {
    if (status === 'published') {
      return '已发布'
    } else if (status === 'draft') {
      return '草稿'
    } else if (status === 'pending') {
      return '待处理'
    } else if (status === 'generating') {
      return '生成中'
    } else {
      return status
    }
  }

  private getStatusColor(status: string): string {
    if (status === 'published') {
      return Colors.STATUS_PUBLISHED_TEXT
    } else if (status === 'draft') {
      return Colors.STATUS_DRAFT_TEXT
    } else if (status === 'pending') {
      return Colors.STATUS_PENDING_TEXT
    } else if (status === 'generating') {
      return Colors.STATUS_GENERATING_TEXT
    } else {
      return Colors.TEXT_HINT
    }
  }

  private getStatusBgColor(status: string): string {
    if (status === 'published') {
      return Colors.STATUS_PUBLISHED_BG
    } else if (status === 'draft') {
      return Colors.STATUS_DRAFT_BG
    } else if (status === 'pending') {
      return Colors.STATUS_PENDING_BG
    } else if (status === 'generating') {
      return Colors.STATUS_GENERATING_BG
    } else {
      return Colors.BG_SECONDARY
    }
  }

  private getPrimaryActionLabel(status: string): string {
    if (status === 'published') {
      return '维护内容'
    } else if (status === 'pending') {
      return '继续处理'
    } else if (status === 'generating') {
      return '查看进度'
    } else if (status === 'draft') {
      return '继续编辑'
    } else {
      return '打开文章'
    }
  }
}
