// 仪表盘页面 — 统计卡片 + 快捷操作

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { TemplateDao } from '../services/db/TemplateDao'
import { KeywordDao } from '../services/db/KeywordDao'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

class ArticleEditorParam {
  articleId: string = ''
}

@Component
export struct DashboardPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') @Watch('onUserIdChanged') currentUserId: string = ''
  @StorageProp('currentUserRole') currentUserRole: string = 'user'
  @StorageProp('dashboardRefreshSignal') @Watch('onRefreshSignal') dashboardRefreshSignal: number = 0

  @State articleCount: number = 0
  @State publishedCount: number = 0
  @State draftCount: number = 0
  @State siteCount: number = 0
  @State templateCount: number = 0
  @State keywordCount: number = 0
  @State isLoading: boolean = true

  // 快速开始进度
  @State hasSites: boolean = false
  @State hasAISettings: boolean = false
  @State hasTemplates: boolean = false
  @State hasArticles: boolean = false

  aboutToAppear(): void {
    this.loadStats()
  }

  // 当 currentUserId 从空字符串变为有效值时自动加载数据
  private onUserIdChanged(): void {
    if (this.currentUserId.length > 0) {
      this.loadStats()
    }
  }

  private onRefreshSignal(): void {
    this.loadStats()
  }

  build() {
    Scroll() {
      Column() {
        // 头部区域
        this.HeaderArea()

        // 统计卡片网格
        this.StatsGrid()

        // 快捷操作区域
        this.QuickActionsArea()

        // 快速开始指南（未完成时显示）
        if (!this.isSetupComplete()) {
          this.QuickStartGuide()
        }

        // 功能亮点卡片
        this.FeatureCards()

        // 底部留白
        Blank().height(Spacing.XL)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BG_PRIMARY)
    .scrollBar(BarState.Off)
  }

  @Builder
  HeaderArea() {
    Row() {
      Column({ space: Spacing.XS }) {
        Text('WordPress CMS')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)

        Row({ space: Spacing.SM }) {
          Text('欢迎回来')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_SECONDARY)

          // 角色徽章
          Text(this.getRoleLabel())
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_ON_PRIMARY)
            .backgroundColor(this.currentUserRole === 'admin' ? Colors.PRIMARY : Colors.SUCCESS)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 刷新按钮
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([Colors.PRIMARY])
      }
      .width(40)
      .height(40)
      .backgroundColor(Colors.BG_SECONDARY)
      .onClick(() => {
        this.loadStats()
      UiFeedback.showToast({ message: '数据已刷新' })
      })
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.LG })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StatsGrid() {
    Column({ space: Spacing.MD }) {
      // 第一行
      Row({ space: Spacing.MD }) {
        Column() {
          this.StatCard('文章数', this.articleCount, 'doc_filled_on_doc', Colors.PRIMARY)
        }
        .layoutWeight(1)
        Column() {
          this.StatCard('站点数', this.siteCount, 'link', Colors.SUCCESS)
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 第二行
      Row({ space: Spacing.MD }) {
        Column() {
          this.StatCard('模板数', this.templateCount, 'folder', Colors.WARNING)
        }
        .layoutWeight(1)
        Column() {
          this.StatCard('关键词数', this.keywordCount, 'magnifyingglass', Colors.ERROR)
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 第三行：文章状态统计
      Row({ space: Spacing.MD }) {
        Column() {
          this.StatCard('已发布', this.publishedCount, 'checkmark_circle_fill', Colors.SUCCESS)
        }
        .layoutWeight(1)
        Column() {
          this.StatCard('草稿', this.draftCount, 'doc_text', Colors.TEXT_HINT)
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: Spacing.LG })
  }

  @Builder
  StatCard(label: string, count: number, iconName: string, iconColor: string) {
    Column({ space: Spacing.SM }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(ComponentSize.ICON_LG)
        .fontColor([iconColor])
        .opacity(0.8)

      Text(this.isLoading ? '-' : count.toString())
        .fontSize(Typography.TITLE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.TEXT_PRIMARY)

      Text(label)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_CARD)
    .borderRadius(Radius.LG)
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.05)',
      offsetY: 2
    })
  }

  @Builder
  QuickActionsArea() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row() {
        Text('快捷操作')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')

      // 操作按钮网格
      Row({ space: Spacing.MD }) {
        Column() {
          this.ActionButton('新建文章', 'square_and_pencil', Colors.PRIMARY, () => {
            const param = new ArticleEditorParam()
            param.articleId = 'new'
            this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
          })
        }
        .layoutWeight(1)

        Column() {
          this.ActionButton('管理站点', 'link', Colors.SUCCESS, () => {
            this.navPathStack.pushPathByName(Routes.SITES, null)
          })
        }
        .layoutWeight(1)
      }
      .width('100%')

      Row({ space: Spacing.MD }) {
        Column() {
          this.ActionButton('AI 设置', 'gearshape', Colors.WARNING, () => {
            this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null)
          })
        }
        .layoutWeight(1)

        Column() {
          this.ActionButton('数据管理', 'square_and_arrow_down', Colors.ERROR, () => {
            this.navPathStack.pushPathByName(Routes.DATA_MANAGEMENT, null)
          })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  ActionButton(label: string, iconName: string, bgColor: string, onClickAction: () => void) {
    Column({ space: Spacing.SM }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.TEXT_ON_PRIMARY])

      Text(label)
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: Spacing.LG, bottom: Spacing.LG })
    .backgroundColor(bgColor)
    .borderRadius(Radius.MD)
    .onClick(onClickAction)
  }

  private getRoleLabel(): string {
    switch (this.currentUserRole) {
      case 'admin':
        return '管理员'
      case 'user':
        return '普通用户'
      default:
        return '用户'
    }
  }

  // 检查是否完成所有设置步骤
  private isSetupComplete(): boolean {
    return this.hasSites && this.hasAISettings && this.hasTemplates && this.hasArticles
  }

  // 检查设置进度
  private async checkSetupProgress(): Promise<void> {
    if (this.currentUserId.length === 0) {
      return
    }
    try {
      // 检查站点
      const siteCount = await SiteDao.countByUserId(this.currentUserId)
      this.hasSites = siteCount > 0

      // 检查AI设置
      const aiSettings = await AISettingsDao.findByUserId(this.currentUserId)
      this.hasAISettings = aiSettings.length > 0

      // 检查模板
      const templates = await TemplateDao.findByUserId(this.currentUserId)
      this.hasTemplates = templates.length > 0

      // 检查文章
      const articles = await ArticleDao.findByUserId(this.currentUserId)
      this.hasArticles = articles.length > 0
    } catch (err) {
      Logger.error('Check setup progress failed: %{public}s', String(err))
    }
  }

  private async loadStats(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      // 文章数 + 状态统计
      const articles = await ArticleDao.findByUserId(this.currentUserId)
      this.articleCount = articles.length
      let published = 0
      let draft = 0
      for (const article of articles) {
        if (article.status === 'published') {
          published++
        } else {
          draft++
        }
      }
      this.publishedCount = published
      this.draftCount = draft

      // 站点数
      this.siteCount = await SiteDao.countByUserId(this.currentUserId)

      // 模板数
      const templates = await TemplateDao.findByUserId(this.currentUserId)
      this.templateCount = templates.length

      // 关键词数
      const keywords = await KeywordDao.findByUserId(this.currentUserId)
      this.keywordCount = keywords.length

      // 检查设置进度
      await this.checkSetupProgress()
    } catch (err) {
      Logger.error('Load dashboard stats failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载统计数据失败' })
    } finally {
      this.isLoading = false
    }
  }

  // 快速开始指南
  @Builder
  QuickStartGuide() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row() {
        Text('快速开始')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')

      // 进度指示器
      Row({ space: Spacing.SM }) {
        Text(`${this.getCompletedSteps()}/4`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .fontWeight(FontWeight.Medium)
        Text('步骤完成')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 检查项列表
      Column({ space: Spacing.SM }) {
        this.SetupCheckItem(
          '添加WordPress站点',
          this.hasSites,
          () => {
            this.navPathStack.pushPathByName(Routes.SITES, null)
          }
        )
        this.SetupCheckItem(
          '配置AI设置',
          this.hasAISettings,
          () => {
            this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null)
          }
        )
        this.SetupCheckItem(
          '创建文章模板',
          this.hasTemplates,
          () => {
            this.navPathStack.pushPathByName(Routes.TEMPLATES, null)
          }
        )
        this.SetupCheckItem(
          '创作第一篇文章',
          this.hasArticles,
          () => {
            const param = new ArticleEditorParam()
            param.articleId = 'new'
            this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
          }
        )
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_CARD)
    .borderRadius(Radius.LG)
    .margin({ top: Spacing.LG })
  }

  // 设置检查项
  @Builder
  SetupCheckItem(label: string, completed: boolean, onTapAction: () => void) {
    Row({ space: Spacing.SM }) {
      // 状态图标
      if (completed) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([Colors.SUCCESS])
      } else {
        SymbolGlyph($r('sys.symbol.circle'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([Colors.TEXT_HINT])
      }

      // 标签
      Text(label)
        .fontSize(Typography.BODY)
        .fontColor(completed ? Colors.TEXT_SECONDARY : Colors.TEXT_PRIMARY)
        .fontWeight(completed ? FontWeight.Regular : FontWeight.Medium)
        .decoration({ type: completed ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)

      // 箭头（未完成时显示）
      if (!completed) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([Colors.TEXT_HINT])
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
    .onClick(onTapAction)
  }

  // 获取已完成步骤数
  private getCompletedSteps(): number {
    let count = 0
    if (this.hasSites) count++
    if (this.hasAISettings) count++
    if (this.hasTemplates) count++
    if (this.hasArticles) count++
    return count
  }

  // 功能亮点卡片
  @Builder
  FeatureCards() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row() {
        Text('功能亮点')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .margin({ top: Spacing.LG })

      // 卡片网格
      Column({ space: Spacing.MD }) {
        // AI智能生成
        this.FeatureCard(
          'doc_filled_on_doc',
          'AI智能生成',
          'AI驱动的文章创作，基于关键词和模板自动生成高质量内容',
          Colors.PRIMARY
        )

        // 多站点管理
        this.FeatureCard(
          'link',
          '多站点管理',
          '集中管理多个WordPress站点，轻松切换发布目标',
          Colors.SUCCESS
        )

        // 模板系统
        this.FeatureCard(
          'folder',
          '模板系统',
          '自定义文章生成模板，支持多种文章类型和风格',
          Colors.WARNING
        )
      }
      .width('100%')
    }
    .width('100%')
  }

  // 单个功能卡片
  @Builder
  FeatureCard(iconName: string, title: string, description: string, accentColor: string) {
    Row({ space: Spacing.MD }) {
      // 图标
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([accentColor])
      }
      .width(48)
      .height(48)
      .backgroundColor(accentColor + '20')
      .borderRadius(Radius.MD)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 内容
      Column({ space: Spacing.XS }) {
        Text(title)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(Colors.TEXT_PRIMARY)
          .width('100%')

        Text(description)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_CARD)
    .borderRadius(Radius.LG)
  }
}
