// 数据管理页面 — 对标 React DataManagement.tsx
// 使用 DataExportService 处理所有导出/导入操作

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { ExportData, ImportResult, DataExportService } from '../services/export/DataExportService'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { TemplateDao } from '../services/db/TemplateDao'
import { KeywordDao } from '../services/db/KeywordDao'
import { TopicDao } from '../services/db/TopicDao'
import { VersionDao } from '../services/db/VersionDao'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

@Component
export struct DataManagementPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  @State isLoading: boolean = true
  @State articleCount: number = 0
  @State siteCount: number = 0
  @State templateCount: number = 0
  @State keywordCount: number = 0
  @State topicCount: number = 0

  @State isExporting: boolean = false
  @State isImporting: boolean = false
  @State encryptExport: boolean = true
  @State lastRestoreResultTitle: string = ''
  @State lastRestoreResultSummary: string = ''
  @State lastRestoreResultColor: string = Colors.TEXT_HINT

  aboutToAppear(): void {
    this.loadStats()
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部工具栏
          this.ToolbarArea()

          // 内容区
          Scroll() {
            Column({ space: Spacing.LG }) {
              // 统计卡片
              this.StatsCard()

              // 数据生命周期说明
              this.LifecycleCard()

              // 导出数据区域
              this.ExportSection()

              // 导入数据区域
              this.ImportSection()

              // 清除数据区域
              this.ClearSection()

              // 恢复结果反馈
              if (this.lastRestoreResultSummary.length > 0) {
                this.RestoreFeedbackCard(this.lastRestoreResultTitle, this.lastRestoreResultSummary, this.lastRestoreResultColor)
              }
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
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== 工具栏 ==========

  @Builder
  ToolbarArea() {
    Row() {
      // 标题
      Text('数据管理')
        .fontSize(Typography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Colors.PRIMARY)

      // 占位，保持布局平衡
      Row()
        .width(60)
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 统计卡片 ==========

  @Builder
  StatsCard() {
    Column({ space: Spacing.MD }) {
      Text('数据概览')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .width('100%')

      if (this.isLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(Colors.PRIMARY)
          Text('加载中...')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_HINT)
            .margin({ left: Spacing.SM })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(Spacing.LG)
      } else {
        // 统计数据网格
        Row({ space: Spacing.MD }) {
          this.StatItem('文章', this.articleCount, $r('sys.symbol.doc_filled_on_doc'))
          this.StatItem('站点', this.siteCount, $r('sys.symbol.link'))
        }
        .width('100%')

        Row({ space: Spacing.MD }) {
          this.StatItem('模板', this.templateCount, $r('sys.symbol.square_and_pencil'))
          this.StatItem('关键词', this.keywordCount, $r('sys.symbol.magnifyingglass'))
        }
        .width('100%')
        .margin({ top: Spacing.MD })

        Row({ space: Spacing.MD }) {
          this.StatItem('主题', this.topicCount, $r('sys.symbol.folder'))
          this.StatItem('总计', this.articleCount + this.siteCount + this.templateCount + this.keywordCount + this.topicCount, $r('sys.symbol.highlighter_line'))
        }
        .width('100%')
        .margin({ top: Spacing.MD })
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  LifecycleCard() {
    Column({ space: Spacing.SM }) {
      Text('推荐操作顺序')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .width('100%')

      Text('先导出并保存文章、文章版本、站点、模板、关键词、主题、AI 设置的当前快照，再在需要时用备份文件恢复这些内容；只有确认备份可用后，再清除本地数据。')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')

      Text('1. 备份当前数据 → 2. 需要时从文件恢复备份 → 3. 确认安全后再清除')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.PRIMARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  StatItem(label: string, count: number, icon: Resource) {
    Row({ space: Spacing.SM }) {
      SymbolGlyph(icon)
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([Colors.PRIMARY])

      Column({ space: Spacing.XS }) {
        Text(`${count}`)
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)

        Text(label)
          .fontSize(Typography.CAPTION)
          .fontColor(Colors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(Colors.BG_PRIMARY)
  }

  // ========== 导出区域 ==========

  @Builder
  ExportSection() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.square_and_arrow_down'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([Colors.PRIMARY])

        Column({ space: Spacing.XS }) {
          Text('1. 备份并导出数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)

          Text('生成当前数据快照，导出到文件后可随时恢复')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('会将当前账号下的文章、文章版本、站点、模板、关键词、主题、AI 设置导出为 JSON 备份文件。可选择加密导出保护敏感信息。')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_HINT)
        .width('100%')

      // 加密导出开关
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.lock'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([Colors.PRIMARY])

        Text('加密导出')
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_PRIMARY)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.encryptExport })
          .selectedColor(Colors.PRIMARY)
          .onChange((isOn: boolean) => {
            this.encryptExport = isOn
          })
      }
      .width('100%')
      .padding(Spacing.MD)
      .borderRadius(Radius.MD)
      .backgroundColor(Colors.BG_PRIMARY)

      // 主导出按钮
      Button(this.isExporting ? '导出中...' : (this.encryptExport ? '导出加密完整备份' : '导出完整备份 (JSON)'), { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isExporting && !this.isImporting)
        .onClick(() => {
          this.handleExport()
        })

      // 分类导出标题
      Text('分类导出')
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)
        .width('100%')
        .margin({ top: Spacing.SM })

      // 分类导出按钮网格
      Column({ space: Spacing.SM }) {
        // 第1行：文章、主题
        Row({ space: Spacing.SM }) {
          Button('导出文章', { type: ButtonType.Normal })
            .width('50%')
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .border({ width: 1, color: Colors.TEXT_HINT, radius: Radius.MD })
            .enabled(!this.isExporting && !this.isImporting)
            .bindMenu([
              { value: 'JSON 格式', action: () => this.handleExportTable('articles') },
              { value: 'Markdown 格式', action: () => this.handleExportArticlesMarkdown() }
            ])

          Button('导出主题', { type: ButtonType.Normal })
            .width('50%')
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .border({ width: 1, color: Colors.TEXT_HINT, radius: Radius.MD })
            .enabled(!this.isExporting && !this.isImporting)
            .bindMenu([
              { value: 'JSON 格式', action: () => this.handleExportTable('topics') },
              { value: '文本格式', action: () => this.handleExportTopicsText() }
            ])
        }
        .width('100%')

        // 第2行：关键词、模板
        Row({ space: Spacing.SM }) {
          Button('导出关键词', { type: ButtonType.Normal })
            .width('50%')
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .border({ width: 1, color: Colors.TEXT_HINT, radius: Radius.MD })
            .enabled(!this.isExporting && !this.isImporting)
            .bindMenu([
              { value: 'JSON 格式', action: () => this.handleExportTable('keywords') },
              { value: '文本格式', action: () => this.handleExportKeywordsText() }
            ])

          Button('导出模板', { type: ButtonType.Normal })
            .width('50%')
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .border({ width: 1, color: Colors.TEXT_HINT, radius: Radius.MD })
            .enabled(!this.isExporting && !this.isImporting)
            .bindMenu([
              { value: 'JSON 格式', action: () => this.handleExportTable('templates') }
            ])
        }
        .width('100%')

        // 第3行：AI设置
        Row({ space: Spacing.SM }) {
          Button('导出 AI 设置', { type: ButtonType.Normal })
            .width('50%')
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(Colors.BG_PRIMARY)
            .fontColor(Colors.TEXT_PRIMARY)
            .fontSize(Typography.BODY)
            .border({ width: 1, color: Colors.TEXT_HINT, radius: Radius.MD })
            .enabled(!this.isExporting && !this.isImporting)
            .bindMenu([
              { value: '安全导出（隐藏 Key）', action: () => this.handleExportAISettingsSafe() },
              { value: '完整导出（含 Key）', action: () => this.handleExportAISettingsFull() }
            ])
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  // ========== 导入区域 ==========

  @Builder
  ImportSection() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([Colors.SUCCESS])

        Column({ space: Spacing.XS }) {
          Text('2. 从备份文件恢复数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)

          Text('从之前导出的 JSON 备份文件恢复内容')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('点击"从备份文件恢复"后，会打开文件选择器让你选择备份文件。系统会自动检测是否加密，如果是加密文件需要解密。恢复前会显示备份内容摘要，确认后再执行恢复。')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_HINT)
        .width('100%')

      Button(this.isImporting ? '恢复中...' : '从备份文件恢复', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.SUCCESS)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isExporting && !this.isImporting)
        .onClick(() => {
          this.handleImport()
        })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  @Builder
  RestoreFeedbackCard(title: string, message: string, accentColor: string) {
    Column({ space: Spacing.XS }) {
      Text(title)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(accentColor)
        .width('100%')

      Text(message)
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  // ========== 清除数据区域 ==========

  @Builder
  ClearSection() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([Colors.ERROR])

        Column({ space: Spacing.XS }) {
          Text('3. 清除本地数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.ERROR)

          Text('仅在确认备份可用后执行，此操作不可恢复')
            .fontSize(Typography.BODY)
            .fontColor(Colors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('警告：此操作会永久删除当前账号在本机上的文章、文章版本、站点、模板、关键词、主题和 AI 设置。请先确认已完成备份且备份文件可用，此操作不可恢复。')
        .fontSize(Typography.CAPTION)
        .fontColor(Colors.ERROR)
        .width('100%')

      Button('清除本地数据', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(Colors.ERROR)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isExporting && !this.isImporting)
        .onClick(() => {
          this.confirmClearAll()
        })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_SECONDARY)
  }

  // ========== 业务逻辑 ==========

  private async loadStats(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      const articles = await ArticleDao.findByUserId(this.currentUserId)
      this.articleCount = articles.length

      const sites = await SiteDao.findByUserId(this.currentUserId)
      this.siteCount = sites.length

      const templates = await TemplateDao.findByUserId(this.currentUserId)
      this.templateCount = templates.length

      const keywords = await KeywordDao.findByUserId(this.currentUserId)
      this.keywordCount = keywords.length

      const topics = await TopicDao.findByUserId(this.currentUserId)
      this.topicCount = topics.length
    } catch (err) {
      Logger.error('Load stats failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载统计数据失败' })
    } finally {
      this.isLoading = false
    }
  }

  // 主导出
  private async handleExport(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportAllData(this.currentUserId, this.encryptExport)
      if (success) {
        UiFeedback.showToast({ message: this.encryptExport ? '加密备份已导出' : '备份已导出' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 分类导出
  private async handleExportTable(tableName: string): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportTableData(this.currentUserId, tableName)
      if (success) {
        UiFeedback.showToast({ message: '导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export table failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // Markdown 导出文章
  private async handleExportArticlesMarkdown(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportArticlesToMarkdown(this.currentUserId)
      if (success) {
        UiFeedback.showToast({ message: '文章 Markdown 导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export articles markdown failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 文本导出主题
  private async handleExportTopicsText(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportTopicsToText(this.currentUserId)
      if (success) {
        UiFeedback.showToast({ message: '主题文本导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export topics text failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 文本导出关键词
  private async handleExportKeywordsText(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportKeywordsToText(this.currentUserId)
      if (success) {
        UiFeedback.showToast({ message: '关键词文本导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export keywords text failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 安全导出 AI 设置
  private async handleExportAISettingsSafe(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportAISettingsSafe(this.currentUserId)
      if (success) {
        UiFeedback.showToast({ message: 'AI 设置安全导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export AI settings safe failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 完整导出 AI 设置
  private async handleExportAISettingsFull(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    this.isExporting = true
    try {
      const success = await DataExportService.exportTableData(this.currentUserId, 'aiSettings')
      if (success) {
        UiFeedback.showToast({ message: 'AI 设置完整导出成功' })
      } else {
        UiFeedback.showToast({ message: '导出失败' })
      }
    } catch (err) {
      Logger.error('Export AI settings full failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  // 导入流程
  private async handleImport(): Promise<void> {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return
    }

    try {
      const jsonStr = await DataExportService.importFromFile()
      if (jsonStr.length === 0) {
        // 用户取消了选择
        return
      }

      // 检查是否加密
      let dataStr = jsonStr
      try {
        const parsed = JSON.parse(jsonStr) as Record<string, Object>
        const isEncrypted = parsed['encrypted'] === true
        const hasPayload = parsed['payload'] !== undefined && parsed['payload'] !== null
        if (isEncrypted && hasPayload) {
          dataStr = await DataExportService.decryptImportData(jsonStr)
        }
      } catch (e) {
        // 不是 JSON 或不是加密格式，使用原始内容
      }

      const importData = DataExportService.validateImportData(dataStr)
      if (importData === null) {
        UiFeedback.showToast({ message: '无效的备份文件' })
        return
      }

      // 构建摘要字符串
      const summary = this.getBackupSummary(importData)

      // 显示确认对话框
      UiFeedback.showConfirm({
        title: '确认从备份恢复',
        message: `将恢复：${summary}\n\n恢复会把内容写入当前账号。是否继续？`,
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: { value: '确认恢复', fontColor: Colors.SUCCESS, action: () => this.executeImport(importData) }
      })
    } catch (err) {
      Logger.error('Import preparation failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '导入失败' })
    }
  }

  private async executeImport(importData: ExportData): Promise<void> {
    this.isImporting = true
    try {
      const result = await DataExportService.importData(importData, this.currentUserId)
      await this.loadStats()

      if (result.totalFailed === 0) {
        UiFeedback.showToast({ message: `恢复完成：导入 ${result.totalImported} 条数据` })
        this.setRestoreResult('恢复完成', `成功导入 ${result.totalImported} 条数据`, Colors.SUCCESS)
      } else {
        UiFeedback.showToast({ message: `恢复完成：导入 ${result.totalImported} 条，失败 ${result.totalFailed} 条` })
        this.setRestoreResult('恢复完成（部分失败）', `导入 ${result.totalImported} 条，失败 ${result.totalFailed} 条`, Colors.WARNING)
      }
    } catch (err) {
      Logger.error('Import execution failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '恢复失败' })
      this.setRestoreResult('恢复失败', String(err), Colors.ERROR)
    } finally {
      this.isImporting = false
    }
  }

  private getBackupSummary(importData: ExportData): string {
    const articleCount = importData.articles ? importData.articles.length : 0
    const versionCount = importData.articleVersions ? importData.articleVersions.length : 0
    const siteCount = importData.sites ? importData.sites.length : 0
    const templateCount = importData.templates ? importData.templates.length : 0
    const keywordCount = importData.keywords ? importData.keywords.length : 0
    const topicCount = importData.topics ? importData.topics.length : 0
    const aiSettingsCount = importData.aiSettings ? importData.aiSettings.length : 0

    return `文章 ${articleCount} 篇、文章版本 ${versionCount} 条、站点 ${siteCount} 个、模板 ${templateCount} 个、关键词 ${keywordCount} 个、主题 ${topicCount} 个、AI 设置 ${aiSettingsCount} 条`
  }

  private setRestoreResult(title: string, summary: string, color: string): void {
    this.lastRestoreResultTitle = title
    this.lastRestoreResultSummary = summary
    this.lastRestoreResultColor = color
  }

  private confirmClearAll(): void {
    UiFeedback.showConfirm({
      title: '确认清除本地数据',
      message: '确定要删除当前账号在本机上的文章、文章版本、站点、模板、关键词、主题和 AI 设置吗？\n\n此操作不可撤销。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '确认删除', fontColor: Colors.ERROR, action: () => this.handleClearAll() }
    })
  }

  private async handleClearAll(): Promise<void> {
    try {
      // 删除文章及其版本
      const articles = await ArticleDao.findByUserId(this.currentUserId)
      for (let i = 0; i < articles.length; i++) {
        await VersionDao.deleteByArticleId(articles[i].id)
        await ArticleDao.deleteById(articles[i].id)
      }

      // 删除站点
      const sites = await SiteDao.findByUserId(this.currentUserId)
      for (let i = 0; i < sites.length; i++) {
        await SiteDao.deleteById(sites[i].id)
      }

      // 删除模板
      const templates = await TemplateDao.findByUserId(this.currentUserId)
      for (let i = 0; i < templates.length; i++) {
        await TemplateDao.deleteById(templates[i].id)
      }

      // 删除关键词
      const keywords = await KeywordDao.findByUserId(this.currentUserId)
      for (let i = 0; i < keywords.length; i++) {
        await KeywordDao.deleteById(keywords[i].id)
      }

      // 删除主题
      const topics = await TopicDao.findByUserId(this.currentUserId)
      for (let i = 0; i < topics.length; i++) {
        await TopicDao.deleteById(topics[i].id)
      }

      // 删除 AI 设置
      const aiSettings = await AISettingsDao.findByUserId(this.currentUserId)
      for (let i = 0; i < aiSettings.length; i++) {
        await AISettingsDao.deleteById(aiSettings[i].id)
      }

      await this.loadStats()
      this.setRestoreResult('本地数据已清除', '页面统计已刷新', Colors.WARNING)
      UiFeedback.showToast({ message: '本地数据已清除', duration: 2000 })
    } catch (err) {
      Logger.error('Clear all data failed: %{public}s', String(err))
      await this.loadStats()
      this.setRestoreResult('清除未完成', String(err), Colors.ERROR)
      UiFeedback.showToast({ message: '清除数据失败' })
    }
  }
}
