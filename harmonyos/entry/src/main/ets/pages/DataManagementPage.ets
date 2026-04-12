// 数据管理页面，对标 React DataManagement.tsx
// 使用 DataExportService 处理所有导出、导入与清理操作

import { ResourceColors, Spacing } from '../constants/DesignTokens'
import { ExportData, DataExportService } from '../services/export/DataExportService'
import { ArticleDao } from '../services/db/ArticleDao'
import { SiteDao } from '../services/db/SiteDao'
import { TemplateDao } from '../services/db/TemplateDao'
import { KeywordDao } from '../services/db/KeywordDao'
import { TopicDao } from '../services/db/TopicDao'
import { VersionDao } from '../services/db/VersionDao'
import { AISettingsDao } from '../services/db/AISettingsDao'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'
import {
  DataManagementOverviewSectionComponent
} from '../components/settings/DataManagementOverviewSection'
import { DataManagementHeaderPanelComponent } from '../components/settings/DataManagementHeaderPanel'
import { DataExportPanelComponent, DataExportAction } from '../components/settings/DataExportPanel'
import { DataImportPanelComponent } from '../components/settings/DataImportPanel'
import { DataDangerZonePanelComponent } from '../components/settings/DataDangerZonePanel'
import { DataManagementSummaryHelper, DataManagementRestoreResult } from '../utils/DataManagementSummaryHelper'
import { AppStorageKeys } from '../constants/AppStorageKeys'

@Component
export struct DataManagementPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp(AppStorageKeys.CURRENT_USER_ID) currentUserId: string = ''

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
  @State lastRestoreResultColor: ResourceColor = ResourceColors.TEXT_HINT

  aboutToAppear(): void {
    this.loadStats()
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          DataManagementHeaderPanelComponent()

          Scroll() {
            Column({ space: Spacing.LG }) {
              DataManagementOverviewSectionComponent({
                isStatsLoading: this.isLoading,
                articleCount: this.articleCount,
                siteCount: this.siteCount,
                templateCount: this.templateCount,
                keywordCount: this.keywordCount,
                topicCount: this.topicCount,
                totalCount: this.articleCount + this.siteCount + this.templateCount + this.keywordCount + this.topicCount,
                restoreTitle: this.lastRestoreResultTitle,
                restoreSummary: this.lastRestoreResultSummary,
                restoreColor: this.lastRestoreResultColor
              })

              DataExportPanelComponent({
                encryptExport: $encryptExport,
                isBusy: this.isExporting || this.isImporting,
                onExportAction: (action: string) => {
                  this.handleExportAction(action)
                }
              })

              DataImportPanelComponent({
                isBusy: this.isExporting || this.isImporting,
                onImport: () => {
                  this.handleImport()
                }
              })

              DataDangerZonePanelComponent({
                isBusy: this.isExporting || this.isImporting,
                onClear: () => {
                  this.confirmClearAll()
                }
              })
            }
            .width('100%')
            .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.BG_PRIMARY)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  private applyRestoreResult(result: DataManagementRestoreResult): void {
    this.lastRestoreResultTitle = result.title
    this.lastRestoreResultSummary = result.summary
    this.lastRestoreResultColor = result.color
  }

  private ensureLoggedIn(): boolean {
    if (this.currentUserId.length === 0) {
      UiFeedback.showToast({ message: '请先登录' })
      return false
    }
    return true
  }

  private async loadStats(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }

    this.isLoading = true
    try {
      const stats: number[] = await Promise.all([
        ArticleDao.countByUserId(this.currentUserId),
        SiteDao.countByUserId(this.currentUserId),
        TemplateDao.countByUserId(this.currentUserId),
        KeywordDao.countByUserId(this.currentUserId),
        TopicDao.countByUserId(this.currentUserId)
      ])

      this.articleCount = stats[0]
      this.siteCount = stats[1]
      this.templateCount = stats[2]
      this.keywordCount = stats[3]
      this.topicCount = stats[4]
    } catch (err) {
      Logger.error('Load stats failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载统计数据失败' })
    } finally {
      this.isLoading = false
    }
  }

  private async handleExportAction(action: string): Promise<void> {
    if (!this.ensureLoggedIn()) {
      return
    }

    switch (action) {
      case DataExportAction.FULL_BACKUP:
        await this.runExportTask(
          this.encryptExport ? '加密备份已导出' : '备份已导出',
          'Export failed',
          () => DataExportService.exportAllData(this.currentUserId, this.encryptExport)
        )
        return
      case DataExportAction.ARTICLES_JSON:
        await this.runExportTask('导出成功', 'Export articles json failed', () =>
          DataExportService.exportTableData(this.currentUserId, 'articles')
        )
        return
      case DataExportAction.ARTICLES_MARKDOWN:
        await this.runExportTask('文章 Markdown 导出成功', 'Export articles markdown failed', () =>
          DataExportService.exportArticlesToMarkdown(this.currentUserId)
        )
        return
      case DataExportAction.TOPICS_JSON:
        await this.runExportTask('导出成功', 'Export topics json failed', () =>
          DataExportService.exportTableData(this.currentUserId, 'topics')
        )
        return
      case DataExportAction.TOPICS_TEXT:
        await this.runExportTask('主题文本导出成功', 'Export topics text failed', () =>
          DataExportService.exportTopicsToText(this.currentUserId)
        )
        return
      case DataExportAction.KEYWORDS_JSON:
        await this.runExportTask('导出成功', 'Export keywords json failed', () =>
          DataExportService.exportTableData(this.currentUserId, 'keywords')
        )
        return
      case DataExportAction.KEYWORDS_TEXT:
        await this.runExportTask('关键词文本导出成功', 'Export keywords text failed', () =>
          DataExportService.exportKeywordsToText(this.currentUserId)
        )
        return
      case DataExportAction.TEMPLATES_JSON:
        await this.runExportTask('导出成功', 'Export templates json failed', () =>
          DataExportService.exportTableData(this.currentUserId, 'templates')
        )
        return
      case DataExportAction.AI_SETTINGS_SAFE:
        await this.runExportTask('AI 设置安全导出成功', 'Export AI settings safe failed', () =>
          DataExportService.exportAISettingsSafe(this.currentUserId)
        )
        return
      case DataExportAction.AI_SETTINGS_FULL:
        await this.runExportTask('AI 设置完整导出成功', 'Export AI settings full failed', () =>
          DataExportService.exportTableData(this.currentUserId, 'aiSettings')
        )
        return
      default:
        Logger.warn('Unknown export action: %{public}s', action)
        return
    }
  }

  private async runExportTask(
    successMessage: string,
    logMessage: string,
    task: () => Promise<boolean>
  ): Promise<void> {
    this.isExporting = true
    try {
      const success = await task()
      UiFeedback.showToast({ message: success ? successMessage : '导出失败' })
    } catch (err) {
      Logger.error(`${logMessage}: %{public}s`, String(err))
      UiFeedback.showToast({ message: '导出失败' })
    } finally {
      this.isExporting = false
    }
  }

  private async handleImport(): Promise<void> {
    if (!this.ensureLoggedIn()) {
      return
    }

    try {
      const jsonStr = await DataExportService.importFromFile()
      if (jsonStr.length === 0) {
        return
      }

      const dataStr = await DataExportService.normalizeImportContent(jsonStr)
      const importData = DataExportService.validateImportData(dataStr)
      if (importData === null) {
        UiFeedback.showToast({ message: '无效的备份文件' })
        return
      }

      const summary = DataManagementSummaryHelper.buildBackupSummary(importData)
      UiFeedback.showConfirm({
        title: '确认从备份恢复',
        message: `将恢复：${summary}\n\n恢复会把内容写入当前账号。是否继续？`,
        primaryButton: { value: '取消', action: () => {} },
        secondaryButton: { value: '确认恢复', fontColor: ResourceColors.SUCCESS, action: () => this.executeImport(importData) }
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
      const restoreResult = DataManagementSummaryHelper.buildImportRestoreResult(result)
      this.applyRestoreResult(restoreResult)
      UiFeedback.showToast({ message: restoreResult.toastMessage })
    } catch (err) {
      Logger.error('Import execution failed: %{public}s', String(err))
      const restoreResult = DataManagementSummaryHelper.buildImportFailureResult(String(err))
      this.applyRestoreResult(restoreResult)
      UiFeedback.showToast({ message: restoreResult.toastMessage })
    } finally {
      this.isImporting = false
    }
  }

  private confirmClearAll(): void {
    UiFeedback.showConfirm({
      title: '确认清除本地数据',
      message: '确定要删除当前账户在本机上的文章、文章版本、站点、模板、关键词、主题和 AI 设置吗？\n\n此操作不可撤销。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '确认删除', fontColor: ResourceColors.ERROR, action: () => this.handleClearAll() }
    })
  }

  private async handleClearAll(): Promise<void> {
    try {
      const articles = await ArticleDao.findByUserId(this.currentUserId)
      for (let i = 0; i < articles.length; i++) {
        await VersionDao.deleteByArticleId(articles[i].id)
        await ArticleDao.deleteById(articles[i].id)
      }

      const sites = await SiteDao.findByUserId(this.currentUserId)
      for (let i = 0; i < sites.length; i++) {
        await SiteDao.deleteById(sites[i].id)
      }

      const templates = await TemplateDao.findByUserId(this.currentUserId)
      for (let i = 0; i < templates.length; i++) {
        await TemplateDao.deleteById(templates[i].id)
      }

      const keywords = await KeywordDao.findByUserId(this.currentUserId)
      for (let i = 0; i < keywords.length; i++) {
        await KeywordDao.deleteById(keywords[i].id)
      }

      const topics = await TopicDao.findByUserId(this.currentUserId)
      for (let i = 0; i < topics.length; i++) {
        await TopicDao.deleteById(topics[i].id)
      }

      const aiSettings = await AISettingsDao.findByUserId(this.currentUserId)
      for (let i = 0; i < aiSettings.length; i++) {
        await AISettingsDao.deleteById(aiSettings[i].id)
      }

      await this.loadStats()
      const restoreResult = DataManagementSummaryHelper.buildClearSuccessResult()
      this.applyRestoreResult(restoreResult)
      UiFeedback.showToast({ message: restoreResult.toastMessage, duration: 2000 })
    } catch (err) {
      Logger.error('Clear all data failed: %{public}s', String(err))
      await this.loadStats()
      const restoreResult = DataManagementSummaryHelper.buildClearFailureResult(String(err))
      this.applyRestoreResult(restoreResult)
      UiFeedback.showToast({ message: restoreResult.toastMessage })
    }
  }
}
