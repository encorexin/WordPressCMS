// 仪表盘页面，展示统计概览与快捷入口

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { TemplateDao } from '../services/db/TemplateDao'
import { KeywordDao } from '../services/db/KeywordDao'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { DashboardHeaderPanelComponent } from '../components/common/DashboardHeaderPanel'
import { DashboardQuickActionsPanelComponent } from '../components/common/DashboardQuickActionsPanel'
import { DashboardFeatureHighlightsComponent } from '../components/common/DashboardFeatureHighlights'
import { AppStorageKeys, UserRole } from '../constants/AppStorageKeys'

class ArticleEditorParam {
  articleId: string = ''
}

@Component
export struct DashboardPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) @Watch('onUserIdChanged') currentUserId: string = ''
  @StorageProp(AppStorageKeys.CURRENT_USER_ROLE) currentUserRole: UserRole = UserRole.User
  @StorageProp(AppStorageKeys.DASHBOARD_REFRESH_SIGNAL) @Watch('onRefreshSignal') dashboardRefreshSignal: number = 0

  @State articleCount: number = 0
  @State publishedCount: number = 0
  @State draftCount: number = 0
  @State siteCount: number = 0
  @State templateCount: number = 0
  @State keywordCount: number = 0
  @State isLoading: boolean = true
  @State hasSites: boolean = false
  @State hasAISettings: boolean = false
  @State hasTemplates: boolean = false
  @State hasArticles: boolean = false

  private hasAppeared: boolean = false

  private resolveUserId(): string {
    if (this.currentUserId.length > 0) {
      return this.currentUserId
    }
    return AppStorage.get<string>(AppStorageKeys.CURRENT_USER_ID) || ''
  }

  aboutToAppear(): void {
    const userId = this.resolveUserId()
    if (userId.length > 0) {
      this.loadStats()
    } else {
      setTimeout(() => {
        const retryId = this.resolveUserId()
        if (retryId.length > 0 && this.articleCount === 0) {
          this.loadStats()
        }
      }, 500)
    }

    setTimeout(() => {
      this.hasAppeared = true
    }, 1000)
  }

  /** 页面重新可见时刷新统计数据 */
  onPageShow(): void {
    if (this.hasAppeared) {
      this.loadStats()
    }
  }

  private onUserIdChanged(): void {
    const userId = this.resolveUserId()
    if (userId.length > 0) {
      this.loadStats()
    }
  }

  private onRefreshSignal(): void {
    const userId = this.resolveUserId()
    if (userId.length > 0) {
      this.loadStats()
    }
  }

  build() {
    Scroll() {
      Column() {
        DashboardHeaderPanelComponent({
          roleLabel: this.getRoleLabel(),
          roleBadgeColor: this.currentUserRole === UserRole.Admin ? ResourceColors.PRIMARY : ResourceColors.SUCCESS,
          onRefresh: () => {
            this.handleManualRefresh()
          }
        })

        // 统计卡片网格 — 直接内联渲染
        Column({ space: Spacing.MD }) {
          Row({ space: Spacing.MD }) {
            StatCardComponent({ count: this.articleCount, label: '文章数', iconName: 'doc_filled_on_doc', iconColor: ResourceColors.PRIMARY, isParentLoading: this.isLoading })
            StatCardComponent({ count: this.siteCount, label: '站点数', iconName: 'link', iconColor: ResourceColors.SUCCESS, isParentLoading: this.isLoading })
          }
          .width('100%')

          Row({ space: Spacing.MD }) {
            StatCardComponent({ count: this.templateCount, label: '模板数', iconName: 'folder', iconColor: ResourceColors.WARNING, isParentLoading: this.isLoading })
            StatCardComponent({ count: this.keywordCount, label: '关键词数', iconName: 'magnifyingglass', iconColor: ResourceColors.ERROR, isParentLoading: this.isLoading })
          }
          .width('100%')

          Row({ space: Spacing.MD }) {
            StatCardComponent({ count: this.publishedCount, label: '已发布', iconName: 'checkmark_circle_fill', iconColor: ResourceColors.SUCCESS, isParentLoading: this.isLoading })
            StatCardComponent({ count: this.draftCount, label: '草稿', iconName: 'doc_text', iconColor: ResourceColors.TEXT_HINT, isParentLoading: this.isLoading })
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: Spacing.LG })

        DashboardQuickActionsPanelComponent({
          onCreateArticle: () => {
            this.openArticleEditor()
          },
          onOpenSites: () => {
            this.navPathStack.pushPathByName(Routes.SITES, null)
          },
          onOpenAISettings: () => {
            this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null)
          },
          onOpenDataManagement: () => {
            this.navPathStack.pushPathByName(Routes.DATA_MANAGEMENT, null)
          }
        })

        if (!(this.hasSites && this.hasAISettings && this.hasTemplates && this.hasArticles)) {
          // 快速开始引导 — 直接内联渲染
          Column({ space: Spacing.MD }) {
            Row() {
              Text('快速开始')
                .fontSize(Typography.SUBTITLE)
                .fontWeight(FontWeight.Medium)
                .fontColor(ResourceColors.TEXT_PRIMARY)
              Blank()
            }
            .width('100%')

            Row({ space: Spacing.SM }) {
              Text(`${this.getCompletedSteps()}/4`)
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.PRIMARY)
                .fontWeight(FontWeight.Medium)

              Text('步骤完成')
                .fontSize(Typography.BODY)
                .fontColor(ResourceColors.TEXT_SECONDARY)
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)

            Column({ space: Spacing.SM }) {
              StepItemComponent({ isCompleted: this.hasSites, label: '添加 WordPress 站点', onStepClick: () => { this.navPathStack.pushPathByName(Routes.SITES, null) } })
              StepItemComponent({ isCompleted: this.hasAISettings, label: '配置 AI 设置', onStepClick: () => { this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null) } })
              StepItemComponent({ isCompleted: this.hasTemplates, label: '创建文章模板', onStepClick: () => { this.navPathStack.pushPathByName(Routes.TEMPLATES, null) } })
              StepItemComponent({ isCompleted: this.hasArticles, label: '创作第一篇文章', onStepClick: () => { this.openArticleEditor() } })
            }
            .width('100%')
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(ResourceColors.BG_CARD)
          .borderRadius(Radius.LG)
          .margin({ top: Spacing.LG })
        }

        DashboardFeatureHighlightsComponent()
        Blank().height(Spacing.XL)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
    .scrollBar(BarState.Off)
  }

  private handleManualRefresh(): void {
    this.loadStats()
    UiFeedback.showToast({ message: '数据已刷新' })
  }

  private openArticleEditor(): void {
    const param = new ArticleEditorParam()
    param.articleId = 'new'
    this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
  }

  private getRoleLabel(): string {
    switch (this.currentUserRole) {
      case UserRole.Admin:
        return '管理员'
      case UserRole.User:
        return '普通用户'
      default:
        return '用户'
    }
  }

  private async loadStats(): Promise<void> {
    const userId = this.resolveUserId()
    if (userId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    Logger.info('DashboardPage.loadStats', `userId=${userId}`)

    // 每个 count 独立调用，单个失败不影响其他统计
    try {
      this.articleCount = await ArticleDao.countByUserId(userId)
    } catch (err) {
      Logger.error('ArticleDao.countByUserId failed: %{public}s', String(err))
    }

    try {
      this.publishedCount = await ArticleDao.countByUserIdAndStatus(userId, 'published')
    } catch (err) {
      Logger.error('ArticleDao.countByUserIdAndStatus(published) failed: %{public}s', String(err))
    }

    try {
      this.draftCount = await ArticleDao.countByUserIdAndStatus(userId, 'draft')
    } catch (err) {
      Logger.error('ArticleDao.countByUserIdAndStatus(draft) failed: %{public}s', String(err))
    }

    try {
      this.siteCount = await SiteDao.countByUserId(userId)
    } catch (err) {
      Logger.error('SiteDao.countByUserId failed: %{public}s', String(err))
    }

    try {
      this.templateCount = await TemplateDao.countByUserId(userId)
    } catch (err) {
      Logger.error('TemplateDao.countByUserId failed: %{public}s', String(err))
    }

    try {
      this.keywordCount = await KeywordDao.countByUserId(userId)
    } catch (err) {
      Logger.error('KeywordDao.countByUserId failed: %{public}s', String(err))
    }

    let aiSettingsCount: number = 0
    try {
      aiSettingsCount = await AISettingsDao.countByUserId(userId)
    } catch (err) {
      Logger.error('AISettingsDao.countByUserId failed: %{public}s', String(err))
    }

    // 设置快速开始步骤状态
    this.hasArticles = this.articleCount > 0
    this.hasSites = this.siteCount > 0
    this.hasTemplates = this.templateCount > 0
    this.hasAISettings = aiSettingsCount > 0

    Logger.info('DashboardPage.loadStats',
      `articles=${this.articleCount}, sites=${this.siteCount}, templates=${this.templateCount}, ` +
      `keywords=${this.keywordCount}, aiSettings=${aiSettingsCount}`)

    this.isLoading = false
  }

  private getCompletedSteps(): number {
    let count = 0
    if (this.hasSites) {
      count++
    }
    if (this.hasAISettings) {
      count++
    }
    if (this.hasTemplates) {
      count++
    }
    if (this.hasArticles) {
      count++
    }
    return count
  }
}

/** 统计卡片子组件 — 用 @Prop 接收父组件的值 */
@Component
struct StatCardComponent {
  @Prop count: number = 0
  @Prop label: string = ''
  @Prop iconName: string = ''
  @Prop iconColor: ResourceColor = ResourceColors.PRIMARY
  @Prop isParentLoading: boolean = true

  build() {
    Column() {
      Column({ space: Spacing.SM }) {
        SymbolGlyph($r(`sys.symbol.${this.iconName}`))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([this.iconColor])
          .opacity(0.8)

        Text(this.isParentLoading ? '-' : `${this.count}`)
          .fontSize(Typography.TITLE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.TEXT_PRIMARY)

        Text(this.label)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
      }
      .width('100%')
      .padding(Spacing.BASE)
      .backgroundColor(ResourceColors.BG_CARD)
      .borderRadius(Radius.LG)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    }
    .layoutWeight(1)
  }
}

/** 步骤项子组件 — 用 @Prop 接收完成状态 */
@Component
struct StepItemComponent {
  @Prop isCompleted: boolean = false
  @Prop label: string = ''
  onStepClick: () => void = () => {}

  build() {
    Row({ space: Spacing.SM }) {
      if (this.isCompleted) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.SUCCESS])
      } else {
        SymbolGlyph($r('sys.symbol.circle'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.TEXT_HINT])
      }

      Text(this.label)
        .fontSize(Typography.BODY)
        .fontColor(this.isCompleted ? ResourceColors.TEXT_SECONDARY : ResourceColors.TEXT_PRIMARY)
        .fontWeight(this.isCompleted ? FontWeight.Regular : FontWeight.Medium)
        .decoration({ type: this.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)

      if (!this.isCompleted) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.TEXT_HINT])
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
    .onClick(() => { this.onStepClick() })
  }
}
