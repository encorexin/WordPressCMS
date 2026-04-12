// 站点管理页面 — 对标 React Sites.tsx

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { WordPressSite } from '../models/WordPressSite'
import { SiteDao } from '../services/db/SiteDao'
import { WordPressApi, WPResult } from '../services/http/WordPressApi'


import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import { SiteFormDialogComponent } from '../components/site/SiteFormDialog'
import { SiteCardComponent } from '../components/site/SiteCard'
import { BasicDataSource, calcCachedCount } from '../utils/BasicDataSource'
import { AppStorageKeys } from '../constants/AppStorageKeys'

@Component
export struct SitesPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''

  @State sites: WordPressSite[] = []
  @State isLoading: boolean = true
  @State showFormDialog: boolean = false
  @State editingSite: WordPressSite | null = null
  @State testingId: string = ''  // 正在测试连接的站点 ID
  private siteDataSource: BasicDataSource<WordPressSite> = new BasicDataSource<WordPressSite>([])

  aboutToAppear(): void {
    this.loadSites()
  }

  build() {
    Stack() {
      Column() {
        // 标题栏: "站点管理" + count + "添加站点" 按钮
        Row() {
          Column({ space: Spacing.XS }) {
            Text('站点管理')
              .fontSize(Typography.TITLE)
              .fontWeight(FontWeight.Bold)
              .fontColor(ResourceColors.PRIMARY)
            Text(`共 ${this.sites.length} 个站点`)
              .fontSize(Typography.BODY)
              .fontColor(ResourceColors.TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('添加站点', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(ResourceColors.PRIMARY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.editingSite = null
              this.showFormDialog = true
            })
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
        .alignItems(VerticalAlign.Bottom)

        // 站点列表
        if (this.isLoading) {
          this.LoadingSkeleton()
        } else if (this.sites.length === 0) {
          this.EmptyView()
        } else {
          this.SiteList()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ResourceColors.BG_PRIMARY)

      // SiteFormDialogComponent 覆盖层
      if (this.showFormDialog) {
        SiteFormDialogComponent({
          show: this.showFormDialog,
          editingSite: this.editingSite,
          onSave: (name: string, url: string, username: string, password: string) => { this.handleSave(name, url, username, password) },
          onClose: () => { this.showFormDialog = false; this.editingSite = null }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SiteList() {
    List({ space: Spacing.MD }) {
      LazyForEach(this.siteDataSource, (site: WordPressSite) => {
        ListItem() {
          SiteCardComponent({
            site: site,
            isTesting: this.testingId === site.id,
            onEdit: () => { this.handleEditStart(site) },
            onDelete: () => { this.handleDelete(site) },
            onTest: () => { this.handleTestConnection(site) }
          })
        }
      }, (site: WordPressSite) => site.id)
    }
    .cachedCount(calcCachedCount(10))
    .width('100%')
    .layoutWeight(1)
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.BASE })
    .scrollBar(BarState.Off)
  }

  @Builder
  EmptyView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.link'))
        .fontSize(64)
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无站点')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text('点击"添加站点"按钮开始添加您的 WordPress 网站')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  @Builder
  LoadingSkeleton() {
    Column({ space: Spacing.MD }) {
      ForEach([1, 2, 3], (_: number) => {
        Column({ space: Spacing.SM }) {
          Row()
            .width('60%')
            .height(20)
            .borderRadius(Radius.SM)
            .backgroundColor(ResourceColors.BG_SECONDARY)
          Row()
            .width('100%')
            .height(16)
            .borderRadius(Radius.SM)
            .backgroundColor(ResourceColors.BG_SECONDARY)
          Row()
            .width('40%')
            .height(16)
            .borderRadius(Radius.SM)
            .backgroundColor(ResourceColors.BG_SECONDARY)
        }
        .width('100%')
        .padding(Spacing.BASE)
        .borderRadius(Radius.LG)
        .backgroundColor(ResourceColors.BG_SECONDARY)
      }, (item: number) => item.toString())
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: Spacing.BASE, right: Spacing.BASE })
  }

  // ========== 业务逻辑 ==========

  private async loadSites(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.sites = []
      this.siteDataSource.setData([])
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      this.sites = await SiteDao.findByUserId(this.currentUserId)
      this.siteDataSource.setData(this.sites)
    } catch (err) {
      Logger.error('Load sites failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载站点失败' })
    } finally {
      this.isLoading = false
    }
  }

  private async handleSave(name: string, url: string, username: string, password: string): Promise<void> {
    try {
      if (this.editingSite !== null) {
        // 更新
        this.editingSite.siteName = name
        this.editingSite.siteUrl = url
        this.editingSite.username = username
        this.editingSite.appPassword = password
        await SiteDao.update(this.editingSite)
        UiFeedback.showToast({ message: '站点更新成功' })
      } else {
        // 新增
        await SiteDao.insert(this.currentUserId, name, url, username, password)
        UiFeedback.showToast({ message: '站点添加成功' })
      }
      this.showFormDialog = false
      this.editingSite = null
      await this.loadSites()
    } catch (err) {
      Logger.error('Save site failed: %{public}s', String(err))
      UiFeedback.showToast({ message: this.editingSite !== null ? '更新失败' : '添加失败' })
    }
  }

  private handleEditStart(site: WordPressSite): void {
    this.editingSite = site
    this.showFormDialog = true
  }

  private async handleTestConnection(site: WordPressSite): Promise<void> {
    this.testingId = site.id
    try {
      const result: WPResult = await WordPressApi.testConnection(site)
      if (result.success) {
        UiFeedback.showToast({ message: '连接成功' })
        site.status = 'active'
      } else {
        UiFeedback.showToast({ message: `连接失败: ${result.message}` })
        site.status = 'inactive'
      }
      await SiteDao.update(site)
      await this.loadSites()
    } catch (err) {
      Logger.error('Test connection failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '测试连接失败' })
    } finally {
      this.testingId = ''
    }
  }

  private handleDelete(site: WordPressSite): void {
    UiFeedback.showConfirm({
      title: '确认删除',
      message: `确定要删除站点"${site.siteName}"吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: ResourceColors.ERROR,
        action: () => {
          this.doDelete(site.id)
        }
      }
    })
  }

  private async doDelete(siteId: string): Promise<void> {
    try {
      await SiteDao.deleteById(siteId)
      UiFeedback.showToast({ message: '站点删除成功' })
      await this.loadSites()
    } catch (err) {
      Logger.error('Delete site failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }
}
