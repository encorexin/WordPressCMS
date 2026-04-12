// 文章列表管理页面 — 支持搜索、状态筛选、站点筛选和批量操作

import { ResourceColors } from '../constants/DesignTokens'
import { Routes, ArticleEditorNavParam } from '../constants/Routes'
import { Article } from '../models/Article'
import { WordPressSite } from '../models/WordPressSite'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { VersionDao } from '../services/db/VersionDao'
import {
  ArticlesFilterPanelComponent,
  ArticleFiltersPanelState,
  ArticleStatusOption
} from '../components/article/ArticlesFilterPanel'
import {
  ArticleContentSectionState,
  ArticleListItemViewModel,
  ArticlesContentSectionComponent
} from '../components/article/ArticlesContentSection'
import { ArticlesBatchDeleteDialogComponent } from '../components/article/ArticlesBatchDeleteDialog'
import { ArticlesHeaderPanelComponent } from '../components/article/ArticlesHeaderPanel'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { BasicDataSource } from '../utils/BasicDataSource'
import pasteboard from '@ohos.pasteboard'
import { AppStorageKeys } from '../constants/AppStorageKeys'

@Component
export struct ArticlesPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''

  @State @Watch('refreshFilteredDataSource') articles: Article[] = []
  @State sites: WordPressSite[] = []
  @State @Watch('refreshFilteredDataSource') searchQuery: string = ''
  @State @Watch('refreshFilteredDataSource') filterStatus: string = 'all'
  @State @Watch('refreshFilteredDataSource') selectedSiteId: string = ''
  @State isLoading: boolean = true
  @State batchMode: boolean = false
  @State selectedIds: string[] = []
  @State showBatchDeleteConfirm: boolean = false
  private filteredArticleDataSource: BasicDataSource<ArticleListItemViewModel> =
    new BasicDataSource<ArticleListItemViewModel>([])
  @StorageProp(AppStorageKeys.ARTICLES_NEED_REFRESH) @Watch('onArticlesNeedRefresh') articlesNeedRefresh: number = 0

  private statusOptions: ArticleStatusOption[] = this.buildStatusOptions()

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

  private buildStatusOptions(): ArticleStatusOption[] {
    const allOption = new ArticleStatusOption()
    allOption.value = 'all'
    allOption.label = '全部'

    const draftOption = new ArticleStatusOption()
    draftOption.value = 'draft'
    draftOption.label = '草稿'

    const publishedOption = new ArticleStatusOption()
    publishedOption.value = 'published'
    publishedOption.label = '已发布'

    const pendingOption = new ArticleStatusOption()
    pendingOption.value = 'pending'
    pendingOption.label = '待处理'

    return [allOption, draftOption, publishedOption, pendingOption]
  }

  private getStatusLabel(status: string): string {
    for (const option of this.statusOptions) {
      if (option.value === status) {
        return option.label
      }
    }
    return status
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

  private refreshFilteredDataSource(): void {
    const filteredArticles = this.getFilteredArticles()
    const data: ArticleListItemViewModel[] = []
    for (const article of filteredArticles) {
      const item = new ArticleListItemViewModel()
      item.article = article
      item.siteName = this.getSiteName(article.siteId)
      item.isSelected = this.isSelected(article.id)
      data.push(item)
    }
    this.filteredArticleDataSource.setData(data)
  }

  private getStatusCount(status: string): number {
    if (status === 'all') {
      return this.articles.length
    }
    return this.articles.filter((article: Article) => article.status === status).length
  }

  private getActiveScopeLabel(): string {
    let label = this.filterStatus === 'all' ? '全部文章' : this.getStatusLabel(this.filterStatus)
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
      return `没有在${this.getStatusLabel(this.filterStatus)}中找到“${query}”，请尝试调整搜索词或查看全部文章`
    }
    if (query.length > 0) {
      return `标题或关键词中没有匹配“${query}”的文章`
    }
    return `当前没有${this.getStatusLabel(this.filterStatus)}文章，请切换状态查看其他内容`
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
    this.refreshFilteredDataSource()
  }

  private selectAll(): void {
    const filtered = this.getFilteredArticles()
    this.selectedIds = []
    for (const article of filtered) {
      this.selectedIds.push(article.id)
    }
    this.refreshFilteredDataSource()
  }

  private deselectAll(): void {
    this.selectedIds = []
    this.refreshFilteredDataSource()
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

  private toggleBatchMode(): void {
    this.batchMode = !this.batchMode
    this.deselectAll()
  }

  private getSelectedSiteIndex(): number {
    for (let i = 0; i < this.sites.length; i++) {
      if (this.sites[i].id === this.selectedSiteId) {
        return i + 1
      }
    }
    return 0
  }

  private buildFilterPanelState(): ArticleFiltersPanelState {
    const state = new ArticleFiltersPanelState()
    state.statusOptions = this.statusOptions
    state.showSiteFilter = this.sites.length > 0
    state.siteOptions = this.getSiteSelectOptions()
    state.siteIds = this.sites.map((site: WordPressSite) => site.id)
    state.selectedSiteIndex = this.getSelectedSiteIndex()
    state.selectedSiteLabel = this.selectedSiteId.length > 0 ? this.getSiteName(this.selectedSiteId) : '全部站点'
    state.showBatchToolbar = this.batchMode && this.getFilteredArticles().length > 0
    state.selectedCount = this.selectedIds.length
    state.filteredCount = this.getFilteredArticles().length
    state.isAllSelected = this.isAllSelected()
    state.summaryText = this.getResultSummary()
    state.showReset = this.searchQuery.trim().length > 0 || this.filterStatus !== 'all' || this.selectedSiteId.length > 0
    return state
  }

  private buildContentSectionState(): ArticleContentSectionState {
    const state = new ArticleContentSectionState()
    state.isLoading = this.isLoading
    state.hasArticles = this.articles.length > 0
    state.hasResults = this.getFilteredArticles().length > 0
    state.batchMode = this.batchMode
    state.noResultsTitle = this.getNoResultsTitle()
    state.noResultsDescription = this.getNoResultsDescription()
    return state
  }

  // ========== 构建 UI ==========

  build() {
    Column() {
      ArticlesHeaderPanelComponent({
        totalCount: this.articles.length,
        draftCount: this.getStatusCount('draft'),
        pendingCount: this.getStatusCount('pending'),
        publishedCount: this.getStatusCount('published'),
        hasArticles: this.articles.length > 0,
        batchMode: this.batchMode,
        onToggleBatchMode: () => {
          this.toggleBatchMode()
        },
        onOpenCreate: () => {
          this.navigateToEditor('new')
        }
      })

      ArticlesFilterPanelComponent({
        searchQuery: $searchQuery,
        filterStatus: $filterStatus,
        selectedSiteId: $selectedSiteId,
        state: this.buildFilterPanelState(),
        onReset: () => {
          this.resetViewState()
        },
        onToggleSelectAll: (value: boolean) => {
          if (value) {
            this.selectAll()
          } else {
            this.deselectAll()
          }
        },
        onOpenBatchDelete: () => {
          this.showBatchDeleteConfirm = true
        }
      })

      ArticlesContentSectionComponent({
        state: this.buildContentSectionState(),
        dataSource: this.filteredArticleDataSource,
        onCreate: () => {
          this.navigateToEditor('new')
        },
        onReset: () => {
          this.resetViewState()
        },
        onOpen: (articleId: string) => {
          this.navigateToEditor(articleId)
        },
        onPreview: (article: Article) => {
          this.handlePreview(article)
        },
        onDelete: (article: Article) => {
          this.confirmDeleteArticle(article)
        },
        onToggleSelection: (articleId: string) => {
          this.toggleSelection(articleId)
        }
      })

      if (this.showBatchDeleteConfirm) {
        ArticlesBatchDeleteDialogComponent({
          count: this.selectedIds.length,
          onClose: () => {
            this.showBatchDeleteConfirm = false
          },
          onConfirm: () => {
            this.showBatchDeleteConfirm = false
            this.handleBatchDelete()
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
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
      this.refreshFilteredDataSource()
      return
    }
    try {
      this.sites = await SiteDao.findByUserId(this.currentUserId)
      this.refreshFilteredDataSource()
    } catch (err) {
      Logger.error('Load sites failed: %{public}s', String(err))
    }
  }

  private navigateToEditor(articleId: string): void {
    const param = new ArticleEditorNavParam()
    param.articleId = articleId.length > 0 ? articleId : 'new'
    param.sourceType = 'article'
    param.sourceId = ''
    param.initialTitle = ''
    param.initialKeywords = ''
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
        fontColor: ResourceColors.ERROR,
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

}
