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

  // 首次 aboutToAppear 完成后置 true，防止 onVisibleAreaChange 首帧重复加载
  private hasAppeared: boolean = false

  // 可靠获取 userId — @StorageProp 在组件创建初期可能尚未同步完成，
  // 直接从 AppStorage.get 读取作为后备，彻底消除时序问题
  private resolveUserId(): string {
    if (this.currentUserId.length > 0) {
      return this.currentUserId
    }
    return AppStorage.get<string>('currentUserId') || ''
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
    .onVisibleAreaChange([0.0, 1.0], (_isVisible: boolean, currentRatio: number) => {
      // 从子页面返回时组件重新可见 → 自动刷新数据
      if (this.hasAppeared && currentRatio > 0 && !this.isLoading) {
        Logger.info('Dashboard onVisibleAreaChange: became visible, refreshing')
        this.loadStats()
      }
    })
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
          // 文章数 — 直接引用 @State，不通过 @Builder 参数传递
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.doc_filled_on_doc'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.PRIMARY])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.articleCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('文章数')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
        Column() {
          // 站点数
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.link'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.SUCCESS])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.siteCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('站点数')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 第二行
      Row({ space: Spacing.MD }) {
        Column() {
          // 模板数
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.folder'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.WARNING])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.templateCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('模板数')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
        Column() {
          // 关键词数
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.ERROR])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.keywordCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('关键词数')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 第三行：文章状态统计
      Row({ space: Spacing.MD }) {
        Column() {
          // 已发布
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.SUCCESS])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.publishedCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('已发布')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
        Column() {
          // 草稿
          Column({ space: Spacing.SM }) {
            SymbolGlyph($r('sys.symbol.doc_text'))
              .fontSize(ComponentSize.ICON_LG)
              .fontColor([Colors.TEXT_HINT])
              .opacity(0.8)
            Text(this.isLoading ? '-' : `${this.draftCount}`)
              .fontSize(Typography.TITLE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Colors.TEXT_PRIMARY)
            Text('草稿')
              .fontSize(Typography.BODY)
              .fontColor(Colors.TEXT_SECONDARY)
          }
          .width('100%')
          .padding(Spacing.BASE)
          .backgroundColor(Colors.BG_CARD)
          .borderRadius(Radius.LG)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: Spacing.LG })
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
  private async checkSetupProgress(userId: string): Promise<void> {
    if (userId.length === 0) {
      return
    }
    try {
      // 检查站点
      const siteCount = await SiteDao.countByUserId(userId)
      this.hasSites = siteCount > 0

      // 检查AI设置
      const aiSettings = await AISettingsDao.findByUserId(userId)
      this.hasAISettings = aiSettings.length > 0

      // 检查模板
      const templates = await TemplateDao.findByUserId(userId)
      this.hasTemplates = templates.length > 0

      // 检查文章
      const articles = await ArticleDao.findByUserId(userId)
      this.hasArticles = articles.length > 0
    } catch (err) {
      Logger.error('Check setup progress failed: %{public}s', String(err))
    }
  }

  private async loadStats(): Promise<void> {
    const userId = this.resolveUserId()
    if (userId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      const articles = await ArticleDao.findByUserId(userId)
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

      this.siteCount = await SiteDao.countByUserId(userId)

      const templates = await TemplateDao.findByUserId(userId)
      this.templateCount = templates.length

      const keywords = await KeywordDao.findByUserId(userId)
      this.keywordCount = keywords.length

      await this.checkSetupProgress(userId)
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

      // 检查项列表 — 直接引用 @State 变量，不通过 @Builder 参数传递
      Column({ space: Spacing.SM }) {
        // 添加WordPress站点
        Row({ space: Spacing.SM }) {
          if (this.hasSites) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.SUCCESS])
          } else {
            SymbolGlyph($r('sys.symbol.circle'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
          Text('添加WordPress站点')
            .fontSize(Typography.BODY)
            .fontColor(this.hasSites ? Colors.TEXT_SECONDARY : Colors.TEXT_PRIMARY)
            .fontWeight(this.hasSites ? FontWeight.Regular : FontWeight.Medium)
            .decoration({ type: this.hasSites ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
          if (!this.hasSites) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
        }
        .width('100%')
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
        .onClick(() => {
          this.navPathStack.pushPathByName(Routes.SITES, null)
        })

        // 配置AI设置
        Row({ space: Spacing.SM }) {
          if (this.hasAISettings) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.SUCCESS])
          } else {
            SymbolGlyph($r('sys.symbol.circle'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
          Text('配置AI设置')
            .fontSize(Typography.BODY)
            .fontColor(this.hasAISettings ? Colors.TEXT_SECONDARY : Colors.TEXT_PRIMARY)
            .fontWeight(this.hasAISettings ? FontWeight.Regular : FontWeight.Medium)
            .decoration({ type: this.hasAISettings ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
          if (!this.hasAISettings) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
        }
        .width('100%')
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
        .onClick(() => {
          this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null)
        })

        // 创建文章模板
        Row({ space: Spacing.SM }) {
          if (this.hasTemplates) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.SUCCESS])
          } else {
            SymbolGlyph($r('sys.symbol.circle'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
          Text('创建文章模板')
            .fontSize(Typography.BODY)
            .fontColor(this.hasTemplates ? Colors.TEXT_SECONDARY : Colors.TEXT_PRIMARY)
            .fontWeight(this.hasTemplates ? FontWeight.Regular : FontWeight.Medium)
            .decoration({ type: this.hasTemplates ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
          if (!this.hasTemplates) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
        }
        .width('100%')
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
        .onClick(() => {
          this.navPathStack.pushPathByName(Routes.TEMPLATES, null)
        })

        // 创作第一篇文章
        Row({ space: Spacing.SM }) {
          if (this.hasArticles) {
            SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.SUCCESS])
          } else {
            SymbolGlyph($r('sys.symbol.circle'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
          Text('创作第一篇文章')
            .fontSize(Typography.BODY)
            .fontColor(this.hasArticles ? Colors.TEXT_SECONDARY : Colors.TEXT_PRIMARY)
            .fontWeight(this.hasArticles ? FontWeight.Regular : FontWeight.Medium)
            .decoration({ type: this.hasArticles ? TextDecorationType.LineThrough : TextDecorationType.None })
            .layoutWeight(1)
          if (!this.hasArticles) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(ComponentSize.ICON_SM)
              .fontColor([Colors.TEXT_HINT])
          }
        }
        .width('100%')
        .padding({ top: Spacing.SM, bottom: Spacing.SM })
        .onClick(() => {
          const param = new ArticleEditorParam()
          param.articleId = 'new'
          this.navPathStack.pushPathByName(Routes.ARTICLE_EDITOR, param)
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(Colors.BG_CARD)
    .borderRadius(Radius.LG)
    .margin({ top: Spacing.LG })
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
