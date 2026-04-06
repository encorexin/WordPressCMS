// 主入口页面 — 导航 + Tab 框架

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { Routes } from '../constants/Routes'
import { ConfirmDialog } from '../components/common/ConfirmDialog'
import { LoginPageContent } from './LoginPage'
import { DashboardPageContent } from './DashboardPage'
import { ArticlesPageContent } from './ArticlesPage'
import { SitesPageContent } from './SitesPage'
import { ArticleEditorPageContent } from './ArticleEditorPage'
import { AISettingsPageContent } from './AISettingsPage'
import { TemplatesPageContent } from './TemplatesPage'
import { KeywordsPageContent } from './KeywordsPage'
import { TopicsPageContent } from './TopicsPage'
import { DataManagementPageContent } from './DataManagementPage'
import { AdminPageContent } from './AdminPage'
import { AboutPageContent } from './AboutPage'
import { AuthService } from '../services/auth/AuthService'
import { Logger } from '../utils/Logger'
import { UiFeedback, ConfirmOptions } from '../utils/UiFeedback'

@Entry
@Component
struct Index {
  @StorageProp('isLoggedIn') @Watch('onLoginStateChanged') isLoggedIn: boolean = false
  @Provide('navPathStack') navPathStack: NavPathStack = new NavPathStack()
  @State currentTabIndex: number = 0
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm'
  @StorageProp('currentUserId') currentUserId: string = ''
  @StorageProp('currentUserRole') currentUserRole: string = 'user'
  private confirmDialogController: CustomDialogController | null = null

  aboutToAppear(): void {
    AppStorage.setOrCreate<number>('dashboardRefreshSignal', 0)
    UiFeedback.setConfirmHandler((options: ConfirmOptions) => {
      this.openConfirmDialog(options)
    })
  }

  aboutToDisappear(): void {
    this.closeConfirmDialog()
    UiFeedback.setConfirmHandler(null)
  }

  // 登录状态变更时，触发 Dashboard 刷新信号让统计数据加载
  private onLoginStateChanged(): void {
    if (this.isLoggedIn) {
      const current = AppStorage.get<number>('dashboardRefreshSignal') ?? 0
      AppStorage.setOrCreate<number>('dashboardRefreshSignal', current + 1)
    }
  }

  build() {
    Navigation(this.navPathStack) {
      if (!this.isLoggedIn) {
        LoginPageContent()
      } else {
        Tabs({ barPosition: BarPosition.End }) {
          // Tab 0: 首页
          TabContent() {
            DashboardPageContent()
          }
          .tabBar(this.TabBarBuilder(0, '首页', 'house', 'house_fill'))

          // Tab 1: 文章
          TabContent() {
            ArticlesPageContent()
          }
          .tabBar(this.TabBarBuilder(1, '文章', 'square_and_pencil', 'square_and_pencil'))

          // Tab 2: 站点
          TabContent() {
            SitesPageContent()
          }
          .tabBar(this.TabBarBuilder(2, '站点', 'link', 'link'))

          // Tab 3: 设置
          TabContent() {
            this.SettingsTab()
          }
          .tabBar(this.TabBarBuilder(3, '设置', 'gearshape', 'gearshape_fill'))
        }
        .barHeight(ComponentSize.TAB_BAR_HEIGHT)
        .onChange((index: number) => {
          this.currentTabIndex = index
          // 切换到首页Tab时触发Dashboard刷新
          if (index === 0) {
            const current = AppStorage.get<number>('dashboardRefreshSignal') ?? 0
            AppStorage.setOrCreate<number>('dashboardRefreshSignal', current + 1)
          }
        })
      }
    }
    .navDestination(this.PageRouter)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }

  @Builder
  TabBarBuilder(index: number, label: string, iconNormal: string, iconSelected: string) {
    Column({ space: 2 }) {
      SymbolGlyph($r(`sys.symbol.${this.currentTabIndex === index ? iconSelected : iconNormal}`))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([this.currentTabIndex === index ? Colors.PRIMARY : Colors.TEXT_HINT])
        .accessibilityText(label)
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTabIndex === index ? Colors.PRIMARY : Colors.TEXT_HINT)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  SettingsTab() {
    Column() {
      // 标题栏
      Row() {
        Text('设置')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.PRIMARY)
        Blank()
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })

      // 设置列表
      Scroll() {
        Column({ space: Spacing.BASE }) {
          // 内容管理分组
          Column({ space: 0 }) {
            Text('内容管理')
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.TEXT_SECONDARY)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .padding({ left: Spacing.BASE, bottom: Spacing.SM })

            // 主题管理
            this.SettingsListItem('主题管理', 'highlighter_line', () => {
              this.navPathStack.pushPathByName(Routes.TOPICS, null)
            })

            // 模板管理
            this.SettingsListItem('模板管理', 'folder', () => {
              this.navPathStack.pushPathByName(Routes.TEMPLATES, null)
            })

            // 关键词库
            this.SettingsListItem('关键词库', 'magnifyingglass', () => {
              this.navPathStack.pushPathByName(Routes.KEYWORDS, null)
            })
          }
          .width('100%')

          // 系统设置分组
          Column({ space: 0 }) {
            Text('系统设置')
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.TEXT_SECONDARY)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .padding({ left: Spacing.BASE, bottom: Spacing.SM })

            // AI 设置
            this.SettingsListItem('AI 设置', 'gearshape', () => {
              this.navPathStack.pushPathByName(Routes.AI_SETTINGS, null)
            })

            // 数据管理
            this.SettingsListItem('数据管理', 'square_and_arrow_down', () => {
              this.navPathStack.pushPathByName(Routes.DATA_MANAGEMENT, null)
            })

            // 用户管理 (仅管理员可见)
            if (this.currentUserRole === 'admin') {
              this.SettingsListItem('用户管理', 'person_2', () => {
                this.navPathStack.pushPathByName(Routes.ADMIN, null)
              })
            }
          }
          .width('100%')

          // 其他
          Column({ space: 0 }) {
            Text('其他')
              .fontSize(Typography.CAPTION)
              .fontColor(Colors.TEXT_SECONDARY)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .padding({ left: Spacing.BASE, bottom: Spacing.SM })

            // 关于
            this.SettingsListItem('关于', 'doc_filled_on_doc', () => {
              this.navPathStack.pushPathByName(Routes.ABOUT, null)
            })
          }
          .width('100%')

          // 退出登录
          Column({ space: 0 }) {
            this.SettingsListItem('退出登录', 'xmark', () => {
              this.handleLogout()
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BG_PRIMARY)
  }

  @Builder
  SettingsListItem(label: string, iconName: string, onClickAction: () => void) {
    Row({ space: Spacing.MD }) {
      SymbolGlyph($r(`sys.symbol.${iconName}`))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.TEXT_SECONDARY])

      Text(label)
        .fontSize(Typography.BODY_LARGE)
        .fontColor(Colors.TEXT_PRIMARY)

      Blank()

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.ARROW])
    }
    .width('100%')
    .height(ComponentSize.LIST_ITEM_HEIGHT)
    .padding({ left: Spacing.BASE, right: Spacing.BASE })
    .backgroundColor(Colors.BG_SECONDARY)
    .borderRadius(Radius.MD)
    .margin({ bottom: Spacing.SM })
    .onClick(onClickAction)
  }

  @Builder
  PageRouter(name: string) {
    // 已自带 NavDestination 的页面直接渲染
    if (name === Routes.ARTICLE_EDITOR) {
      ArticleEditorPageContent()
    } else if (name === Routes.AI_SETTINGS) {
      AISettingsPageContent()
    } else if (name === Routes.TEMPLATES) {
      TemplatesPageContent()
    } else if (name === Routes.KEYWORDS) {
      KeywordsPageContent()
    } else if (name === Routes.TOPICS) {
      TopicsPageContent()
    } else if (name === Routes.DATA_MANAGEMENT) {
      DataManagementPageContent()
    } else if (name === Routes.ADMIN) {
      AdminPageContent()
    } else if (name === Routes.ABOUT) {
      AboutPageContent()
    }
    // Tab 页面作为 NavDestination 目标时需要包装
    else if (name === Routes.DASHBOARD) {
      NavDestination() {
        DashboardPageContent()
      }.hideTitleBar(true)
    } else if (name === Routes.ARTICLES) {
      NavDestination() {
        ArticlesPageContent()
      }.hideTitleBar(true)
    } else if (name === Routes.SITES) {
      NavDestination() {
        SitesPageContent()
      }.hideTitleBar(true)
    }
  }

  private handleLogout(): void {
    UiFeedback.showConfirm({
      title: '确认退出',
      message: '确定要退出登录吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '退出',
        fontColor: Colors.ERROR,
        action: () => {
          AuthService.logout()
          UiFeedback.showToast({ message: '已退出登录' })
        }
      }
    })
  }

  private openConfirmDialog(options: ConfirmOptions): void {
    try {
      this.closeConfirmDialog()

      let dialogController: CustomDialogController | null = null
      const closeDialog = () => {
        if (dialogController === null || this.confirmDialogController !== dialogController) {
          return
        }

        this.confirmDialogController = null
        dialogController.close()
      }

      dialogController = new CustomDialogController({
        builder: ConfirmDialog({
          title: options.title,
          message: options.message,
          cancelText: options.primaryButton.value,
          confirmText: options.secondaryButton.value,
          cancelFontColor: options.primaryButton.fontColor ?? Colors.TEXT_PRIMARY,
          confirmFontColor: options.secondaryButton.fontColor ?? Colors.PRIMARY,
          onCancel: () => {
            this.executeConfirmAction('primary', options.primaryButton.action, closeDialog)
          },
          onConfirm: () => {
            this.executeConfirmAction('secondary', options.secondaryButton.action, closeDialog)
          }
        }),
        autoCancel: options.autoCancel ?? true,
        customStyle: true
      })

      this.confirmDialogController = dialogController
      dialogController.open()
    } catch (err) {
      Logger.error('Index.openConfirmDialog failed: %{public}s', String(err))
    }
  }

  private closeConfirmDialog(): void {
    try {
      if (this.confirmDialogController === null) {
        return
      }

      const dialogController = this.confirmDialogController
      this.confirmDialogController = null
      dialogController.close()
    } catch (err) {
      Logger.error('Index.closeConfirmDialog failed: %{public}s', String(err))
    }
  }

  private executeConfirmAction(buttonType: string, action: () => void, closeDialog: () => void): void {
    try {
      action()
    } catch (err) {
      Logger.error('Index.executeConfirmAction failed on %{public}s button: %{public}s', buttonType, String(err))
    } finally {
      closeDialog()
    }
  }
}
